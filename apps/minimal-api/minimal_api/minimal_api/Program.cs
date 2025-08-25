using System.Net.Mime;
using System.Text;
using Microsoft.AspNetCore.Http.Features;

var builder = WebApplication.CreateBuilder(args);


builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

builder.Services.Configure<FormOptions>(options =>
{
    
    options.MultipartBodyLengthLimit = 1 * 1024 * 1024; // Limite máximo de 1mb para evitar envios de imagens grandes
    
});

app.MapPost("/PostImageS3", async (IFormFile file) =>
{
    if (file == null || file.Length == 0)
        return Results.BadRequest("Nenhum arquivo foi enviado.");
    
    var fileName = Path.GetFileName(file.FileName);
    
    if (fileName.Length > 64)
        return Results.BadRequest("O nome do arquivo é muito grande.");
    
    if (file.ContentType != MediaTypeNames.Image.Png)
        return Results.BadRequest("O arquivo enviado não é uma imagem, caso seja utilize PNG.");
    
    var extension = Path.GetExtension(file.FileName);
    var guidFileName = $"{fileName}-{Guid.NewGuid()}{extension}";
    
    Directory.CreateDirectory("uploads");
    var uploadPath = Path.Combine("uploads", guidFileName);
    
    using var stream = File.OpenWrite(uploadPath);
    await file.CopyToAsync(stream);
    
    return Results.Ok("Imagem enviada com suceso.");
    
}).DisableAntiforgery(); // Não é necessário em um endpoint de upload de imagem pois não sofre risco de CSRF.


app.UseHttpsRedirection();

app.Run();

