# Estágio 1: Build (Compilação)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copia todos os arquivos do projeto para o container
COPY . .

# Publica a API
# Ajuste o caminho se necessário, mas com o Root Directory na raiz, este caminho deve funcionar
RUN dotnet publish "src/JhonnyHomeStudio.Api/JhonnyHomeStudio.Api.csproj" -c Release -o out

# Estágio 2: Runtime (Execução)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/src/JhonnyHomeStudio.Api/out .

# Expõe a porta que o .NET usa por padrão
EXPOSE 8080
ENTRYPOINT ["dotnet", "JhonnyHomeStudio.Api.dll"]