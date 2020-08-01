from PIL import Image

image = Image.open("image.png")
pixels = image.load()

for y in range(128):
    for x in range(128):
        print(format(pixels[x,y], "x").zfill(2))
    print()
