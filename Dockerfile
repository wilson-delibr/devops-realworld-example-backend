#build container
FROM mcr.microsoft.com/dotnet/sdk:3.1-alpine as build

WORKDIR /build
COPY . .
RUN dotnet run -p build/build.csproj

#runtime container
FROM mcr.microsoft.com/dotnet/aspnet:3.1-alpine

COPY --from=build /build/publish /app
WORKDIR /app
RUN apk add icu-libs
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
EXPOSE 5000

ENTRYPOINT ["dotnet", "Conduit.dll"]
