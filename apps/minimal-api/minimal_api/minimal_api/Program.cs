using System.Net.Mime;
using System.Text;
using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using minimal_api;

var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 1 * 1024 * 1024; // Limite máximo de 1mb para evitar envios de imagens grandes
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowLocalhost", policy =>
    {
        policy.WithOrigins("http://127.0.0.1:5500") // origem do seu front
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

builder.Services.AddSignalR();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseCors("AllowLocalhost");

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapHub<myHub>("/connection");

app.MapPost("/PostImageBlob", async (HttpRequest request
    ,IFormFile file,
    IHubContext<myHub> hubContext) =>
{
    if (!(request.Headers.TryGetValue("X-Connection-Id", out var ConnectionIdValues)))
    {
        return Results.BadRequest("Header 'X-Connection-Id' não encontrado.");
    }

    var connectionId = ConnectionIdValues.FirstOrDefault();
    
    
    if (file == null || file.Length == 0)
        return Results.BadRequest("Nenhum arquivo foi enviado.");
    
    var fileName = Path.GetFileName(file.FileName);
    
    if (fileName.Length > 64)
        return Results.BadRequest("O nome do arquivo é muito grande.");
    
    if (file.ContentType != MediaTypeNames.Image.Png)
        return Results.BadRequest("O arquivo enviado não é uma imagem, caso seja utilize PNG.");
    
    var extension = Path.GetExtension(file.FileName);
    var guidFileName = $"{fileName}-{Guid.NewGuid()}{extension}";

    hubContext.Groups.AddToGroupAsync(connectionId, guidFileName);
    
    var blobServiceCliente = new BlobServiceClient(
        new Uri("AzureStorage:BlobServiceUri"),
        new DefaultAzureCredential());

    string containerName = "AzureStorage:ContainerName";

    BlobContainerClient containerClient = blobServiceCliente.GetBlobContainerClient(containerName);
    
    BlobClient blobClient = containerClient.GetBlobClient(guidFileName);

    var metaData = new Dictionary<string, string>
    {
        { "signalr_connection_id", connectionId}
    };
        
        
    await blobClient.UploadAsync(file.OpenReadStream(), new BlobUploadOptions {Metadata = metaData});
    
    return Results.Ok("Imagem enviada com suceso.");
    
}).DisableAntiforgery(); // Não é necessário em um endpoint de upload de imagem pois não sofre risco de CSRF.


app.UseHttpsRedirection();

app.Run();

