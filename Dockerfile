#build container
FROM mcr.microsoft.com/dotnet/sdk:3.1 as build

WORKDIR /build
COPY . .
RUN dotnet run -p build/build.csproj

#runtime container
FROM mcr.microsoft.com/dotnet/aspnet:3.1

COPY --from=build /build/publish /app
WORKDIR /app

ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
EXPOSE 5000

ENTRYPOINT ["dotnet", "Conduit.dll"]
