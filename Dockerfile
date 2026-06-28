# Estágio 1: Build (Compilação)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /source

# Copia tudo para o container
COPY . .

# Publica a API para uma pasta centralizada chamada /app/publish
RUN dotnet publish "src/JhonnyHomeStudio.Api/JhonnyHomeStudio.Api.csproj" -c Release -o /app/publish

# Estágio 2: Runtime (Execução)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Copia os arquivos da pasta centralizada /app/publish para a pasta atual do runtime
COPY --from=build /app/publish .

# Define o ponto de entrada
EXPOSE 8080
ENTRYPOINT ["dotnet", "JhonnyHomeStudio.Api.dll"]