from pathlib import Path
from shutil import which

from PIL import Image, ImageDraw, ImageFont


SIZE = 1024
BLUE = "#1677FF"
WHITE = "#FFFFFF"


def build_icon() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((48, 48, 976, 976), radius=216, fill=BLUE)

    flutter_command = which("flutter")
    if flutter_command is None:
        raise RuntimeError("Flutter must be available on PATH to generate the app icon.")

    flutter_root = Path(flutter_command).resolve().parent.parent
    material_font = (
        flutter_root / "bin" / "cache" / "artifacts" / "material_fonts" / "MaterialIcons-Regular.otf"
    )
    font = ImageFont.truetype(str(material_font), 650)
    snowflake = "\uf516"  # Material Icons: ac_unit_rounded
    bounds = draw.textbbox((0, 0), snowflake, font=font)
    width = bounds[2] - bounds[0]
    height = bounds[3] - bounds[1]
    position = ((SIZE - width) / 2 - bounds[0], (SIZE - height) / 2 - bounds[1])
    draw.text(position, snowflake, font=font, fill=WHITE)

    return image


def main() -> None:
    resource_dir = Path(__file__).resolve().parents[1] / "windows" / "runner" / "resources"
    source_path = resource_dir / "app_icon_source.png"
    icon_path = resource_dir / "app_icon.ico"

    icon = build_icon()
    icon.save(source_path, "PNG", optimize=True)
    icon.save(
        icon_path,
        "ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


if __name__ == "__main__":
    main()
