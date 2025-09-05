using Azure_Function.services;
using Azure;
using Azure.Identity;
using Azure.Messaging.EventGrid;
using Azure.Messaging.EventGrid.SystemEvents;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Google.Protobuf.Reflection;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.SignalR.Management;

var builder = FunctionsApplication.CreateBuilder(args);

builder.ConfigureFunctionsWebApplication();

builder.Services.AddScoped<IImageResizer, ImageResizer>();

builder.Services.AddSignalR().AddAzureSignalR();

builder.Services
    .AddApplicationInsightsTelemetryWorkerService()
    .ConfigureFunctionsApplicationInsights();

builder.Build().Run();


public class UpscaleImage
{
    private readonly ILogger<UpscaleImage> _logger;
    private readonly IImageResizer _imageResizer;
    
            
    public UpscaleImage(ILogger<UpscaleImage> logger, IImageResizer imageResizer)
    {
        _imageResizer = imageResizer;
        _logger = logger;
    }
    
    [Function("UpscaleImage")]
    public async Task Run([EventGridTrigger] EventGridEvent eventGridEvent)
    {
        
        _logger.LogInformation("Evento recebido: {type}, Subject: {subject}", eventGridEvent.EventType,
            eventGridEvent.Subject);

        var eventdata = eventGridEvent.Data.ToObjectFromJson<StorageBlobCreatedEventData>();
        var blobUrl = eventdata.Url;


        BlobClient blobclient = new BlobClient(new Uri(blobUrl), new DefaultAzureCredential());
        Response<BlobProperties> properties = await blobclient.GetPropertiesAsync();

        IDictionary<string, string> metadata = properties.Value.Metadata;

        string connectionId = metadata["signalr_connection_id"];

        _logger.LogInformation("ConnectionId: {connectionId}", connectionId);

        var img = await blobclient.DownloadAsync();
        Stream inputStream = img.Value.Content;

        Stream outputblob = new MemoryStream();

        _imageResizer.Resize(inputStream, outputblob);
        
        var metaData = new Dictionary<string, string>
        {
            { "signalr_connection_id", connectionId}
        };
        
        BlobServiceClient client = new BlobServiceClient(new Uri("https://upscalingstorageacc921.blob.core.windows.net"), new DefaultAzureCredential());
        BlobContainerClient containerClient = client.GetBlobContainerClient("container-image-1returnfor-upscalingpj");
        
        var connectionString = Environment.GetEnvironmentVariable("AzureSignalRConnectionString");
        
        var serviceManager = new ServiceManagerBuilder()
            .WithOptions(o =>
            {
                o.ConnectionString = connectionString;
            })
            .BuildServiceManager();
        
        outputblob.Position = 0;
        
        string originalFileName = Path.GetFileName(new Uri(blobUrl).LocalPath);
        string newBlobName = $"upscaled-{originalFileName}";
        BlobClient blob = containerClient.GetBlobClient(newBlobName);
        await blob.UploadAsync(outputblob, new BlobUploadOptions {Metadata = metaData});
        
        _logger.LogInformation("Upscaled blob {newBlobName}, URI: {blob.Uri}", newBlobName, blob.Uri);


        var hubContext = await serviceManager.CreateHubContextAsync("myHub", CancellationToken.None);
        await hubContext.Clients.Client(connectionId).SendAsync("imageProcessed", blob.Uri.ToString());
        
        _logger.LogInformation("Notificação enviada para {connectionId}", connectionId);

    }
}


