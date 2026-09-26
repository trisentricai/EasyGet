from django.db import migrations

OLD = {
    "primary_color": "#1A73E8",
    "secondary_color": "#FFB300",
    "font_family": "system-ui",
}
NEW = {
    "primary_color": "#2874F0",
    "secondary_color": "#FB641B",
    "font_family": "Inter, system-ui, sans-serif",
}


def to_marketplace_palette(apps, schema_editor):
    """Remap legacy defaults to the Flipkart-style palette.

    Only touches rows still on the old defaults, so any store already
    rebranded by an admin keeps its identity.
    """
    StorefrontTheme = apps.get_model("storefront", "StorefrontTheme")
    for theme in StorefrontTheme.objects.all():
        changed = False
        for field, old in OLD.items():
            if getattr(theme, field) == old:
                setattr(theme, field, NEW[field])
                changed = True
        if theme.button_style == "ROUNDED":
            theme.button_style = "SQUARE"
            changed = True
        if changed:
            theme.save()


def back_to_legacy(apps, schema_editor):
    StorefrontTheme = apps.get_model("storefront", "StorefrontTheme")
    for theme in StorefrontTheme.objects.all():
        changed = False
        for field, new in NEW.items():
            if getattr(theme, field) == new:
                setattr(theme, field, OLD[field])
                changed = True
        if theme.button_style == "SQUARE":
            theme.button_style = "ROUNDED"
            changed = True
        if changed:
            theme.save()


class Migration(migrations.Migration):
    dependencies = [
        ("storefront", "0002_alter_storefronttheme_button_style_and_more"),
    ]

    operations = [
        migrations.RunPython(to_marketplace_palette, back_to_legacy),
    ]
