from django.contrib.auth import get_user_model
from django.test import TestCase

from categories.models import Category
from orders.models import Order
from products.models import Product, ProductVariant
from stores.models import Store

from .models import ChatMessage, ChatRoom, Device, InventorySubscription

User = get_user_model()


class DeviceTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="device@test.com", password="pass")

    def test_register_device(self):
        device = Device.objects.create(
            user=self.user,
            platform=Device.Platform.IOS,
            device_token="token_123",
            user_agent="iOS App/1.0",
        )
        self.assertEqual(device.platform, "IOS")
        self.assertTrue(device.is_active)

    def test_unique_device_token_per_user(self):
        Device.objects.create(
            user=self.user,
            platform=Device.Platform.ANDROID,
            device_token="token_123",
        )
        with self.assertRaises(Exception):
            Device.objects.create(
                user=self.user,
                platform=Device.Platform.IOS,
                device_token="token_123",
            )


class ChatRoomTests(TestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(email="chat1@test.com", password="pass")
        self.user2 = User.objects.create_user(email="chat2@test.com", password="pass")

    def test_create_room(self):
        room = ChatRoom.objects.create(name="Support", type=ChatRoom.RoomType.SUPPORT)
        room.participants.add(self.user1, self.user2)
        self.assertEqual(room.participants.count(), 2)

    def test_add_participant(self):
        room = ChatRoom.objects.create(name="Order Chat", type=ChatRoom.RoomType.ORDER)
        room.participants.add(self.user1)
        room.participants.add(self.user2)
        self.assertEqual(room.participants.count(), 2)


class ChatMessageTests(TestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(email="msg1@test.com", password="pass")
        self.user2 = User.objects.create_user(email="msg2@test.com", password="pass")
        self.room = ChatRoom.objects.create(name="Test Room")
        self.room.participants.add(self.user1, self.user2)

    def test_create_message(self):
        msg = ChatMessage.objects.create(
            room=self.room,
            sender=self.user1,
            content="Hello!",
        )
        self.assertEqual(msg.content, "Hello!")
        self.assertEqual(msg.sender, self.user1)
        self.assertFalse(msg.is_read)

    def test_reply_to_message(self):
        msg1 = ChatMessage.objects.create(
            room=self.room,
            sender=self.user1,
            content="First message",
        )
        msg2 = ChatMessage.objects.create(
            room=self.room,
            sender=self.user2,
            content="Reply",
            reply_to=msg1,
        )
        self.assertEqual(msg2.reply_to, msg1)


class ChatApiSecurityTests(TestCase):
    """HTTP-level guards: no posting into rooms you don't belong to, no
    editing/deleting other participants' messages, no membership management."""

    def setUp(self):
        from rest_framework.test import APIClient

        self.client = APIClient()
        self.user1 = User.objects.create_user(email="sec1@test.com", password="pass")
        self.user2 = User.objects.create_user(email="sec2@test.com", password="pass")
        self.outsider = User.objects.create_user(
            email="sec3@test.com", password="pass"
        )
        self.room = ChatRoom.objects.create(name="Secure Room")
        self.room.participants.add(self.user1, self.user2)

    def test_cannot_post_message_into_foreign_room(self):
        self.client.force_authenticate(user=self.outsider)
        res = self.client.post(
            "/api/v1/realtime/messages/",
            {"room": str(self.room.id), "content": "intruder"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)
        self.assertFalse(self.room.messages.filter(content="intruder").exists())

    def test_participant_cannot_edit_others_message(self):
        msg = ChatMessage.objects.create(
            room=self.room, sender=self.user1, content="original"
        )
        self.client.force_authenticate(user=self.user2)
        res = self.client.patch(
            f"/api/v1/realtime/messages/{msg.id}/",
            {"content": "tampered"},
            format="json",
        )
        self.assertEqual(res.status_code, 403)
        msg.refresh_from_db()
        self.assertEqual(msg.content, "original")

    def test_participant_cannot_delete_others_message(self):
        msg = ChatMessage.objects.create(
            room=self.room, sender=self.user1, content="keep me"
        )
        self.client.force_authenticate(user=self.user2)
        res = self.client.delete(f"/api/v1/realtime/messages/{msg.id}/")
        self.assertEqual(res.status_code, 403)
        self.assertTrue(ChatMessage.objects.filter(pk=msg.pk).exists())

    def test_author_can_edit_own_message(self):
        msg = ChatMessage.objects.create(
            room=self.room, sender=self.user1, content="mine"
        )
        self.client.force_authenticate(user=self.user1)
        res = self.client.patch(
            f"/api/v1/realtime/messages/{msg.id}/",
            {"content": "mine edited"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        msg.refresh_from_db()
        self.assertEqual(msg.content, "mine edited")

    def test_create_room_ignores_supplied_participants(self):
        self.client.force_authenticate(user=self.user1)
        res = self.client.post(
            "/api/v1/realtime/rooms/",
            {
                "name": "Sneaky",
                "type": "SUPPORT",
                "participants": [self.user2.id, self.outsider.id],
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        room = ChatRoom.objects.get(pk=res.data["id"])
        self.assertEqual(list(room.participants.all()), [self.user1])

    def test_non_staff_cannot_add_participant(self):
        self.client.force_authenticate(user=self.user1)
        res = self.client.post(
            f"/api/v1/realtime/rooms/{self.room.id}/add_participant/",
            {"user_id": self.outsider.id},
            format="json",
        )
        self.assertEqual(res.status_code, 403)
        self.assertFalse(self.room.participants.filter(pk=self.outsider.pk).exists())


class InventorySubscriptionTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="sub@test.com", password="pass")
        self.store = Store.objects.create(
            name="Test Store",
            city="Pune",
            state="MH",
            postal_code="411001",
            latitude=18.5204,
            longitude=73.8567,
        )
        category = Category.objects.create(name="Grocery", is_active=True)
        product = Product.objects.create(
            name="Rice 5kg",
            category=category,
            mrp=800.00,
            is_active=True,
        )
        self.variant = ProductVariant.objects.create(
            product=product,
            name="5kg",
            sku="RICE-5KG",
            price=700.00,
            is_active=True,
        )

    def test_create_low_stock_subscription(self):
        sub = InventorySubscription.objects.create(
            user=self.user,
            product_variant=self.variant,
            trigger=InventorySubscription.Trigger.LOW_STOCK,
            threshold=10,
        )
        self.assertEqual(sub.trigger, "LOW_STOCK")
        self.assertEqual(sub.threshold, 10)

    def test_create_out_of_stock_subscription(self):
        sub = InventorySubscription.objects.create(
            user=self.user,
            product_variant=self.variant,
            trigger=InventorySubscription.Trigger.OUT_OF_STOCK,
        )
        self.assertEqual(sub.trigger, "OUT_OF_STOCK")
        self.assertIsNone(sub.threshold)

    def test_unique_subscription_per_user_variant_trigger(self):
        InventorySubscription.objects.create(
            user=self.user,
            product_variant=self.variant,
            trigger=InventorySubscription.Trigger.LOW_STOCK,
            threshold=5,
        )
        with self.assertRaises(Exception):
            InventorySubscription.objects.create(
                user=self.user,
                product_variant=self.variant,
                trigger=InventorySubscription.Trigger.LOW_STOCK,
                threshold=5,
            )