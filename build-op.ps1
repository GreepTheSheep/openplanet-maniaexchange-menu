$compress = @{
    Path = "./info.toml", "./src"
    CompressionLevel = "Fastest"
    DestinationPath = "./ManiaExchange.zip"
}
Compress-Archive @compress -Force

Move-Item -Path "./ManiaExchange.zip" -Destination "./ManiaExchange.op" -Force

Write-Host("✅ Done!")