namespace Azure_Function.services;

public interface IImageResizer
{
    void Resize(Stream input, Stream output);
}