using System.Drawing;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Processing;
using Image = SixLabors.ImageSharp.Image;

namespace Azure_Function.services;

public class ImageResizer : IImageResizer
{
    public void Resize(Stream input, Stream output)
    {
        using (Image image = Image.Load(input))
        {
            image.Mutate(x => x.Resize(image.Width * 2, image.Height * 2));
            image.Save(output, new JpegEncoder());
        }
    }
}