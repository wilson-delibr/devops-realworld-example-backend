#build container
FROM mcr.microsoft.com/dotnet/core/sdk:3.1.402-buster as build

WORKDIR /build
COPY . .
RUN dotnet run -p build/build.csproj

#runtime container
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1.8-alpine3.12
RUN apk add --no-cache tzdata

COPY --from=build /build/publish /app
WORKDIR /app
RUN apk add icu-libs
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
EXPOSE 5000

ENTRYPOINT ["dotnet", "Conduit.dll"]
