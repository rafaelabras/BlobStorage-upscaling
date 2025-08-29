output "signalr_connection_string" {
    value = azurerm_signalr_service.signalR.primary_connection_string

    sensitive = true
}