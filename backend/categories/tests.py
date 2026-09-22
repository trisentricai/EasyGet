from django.test import TestCase

from .models import Category


class CategoryModelTests(TestCase):
    def setUp(self):
        self.grocery = Category.objects.create(
            name="Grocery", is_active=True, sort_order=0
        )
        self.snacks = Category.objects.create(
            name="Snacks", parent=self.grocery, is_active=True, sort_order=1
        )
        self.off = Category.objects.create(
            name="Off", parent=self.grocery, is_active=False
        )

    def test_slug_auto_generated_and_unique(self):
        self.assertEqual(self.grocery.slug, "grocery")
        self.assertEqual(self.snacks.slug, "snacks")

    def test_unique_slug_on_collision(self):
        dup = Category.objects.create(name="Grocery", is_active=True)
        self.assertNotEqual(dup.slug, "grocery")
        self.assertTrue(dup.slug.startswith("grocery"))

    def test_is_subcategory(self):
        self.assertFalse(self.grocery.is_subcategory)
        self.assertTrue(self.snacks.is_subcategory)

    def test_active_children_ordering(self):
        active = list(
            self.grocery.children.filter(is_active=True).order_by("sort_order")
        )
        self.assertEqual([c.id for c in active], [self.snacks.id])

    def test_str_top_level(self):
        self.assertEqual(str(self.grocery), "Grocery")

    def test_str_subcategory(self):
        self.assertEqual(str(self.snacks), "Grocery / Snacks")
