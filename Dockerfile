FROM mcr.microsoft.com/dotnet/core/sdk:3.1 as build-image

#ARG TeamCityProjectName

WORKDIR /home/app

COPY ./*.sln ./
COPY ./*/*.csproj ./
RUN for file in $(ls *.csproj); do mkdir -p ./${file%.*}/ && mv $file ./${file%.*}/; done

RUN dotnet restore

COPY . .

ARG TEAMCITY_PROJECT_NAME
#ENV TEAMCITY_PROJECT_NAME=${TEAMCITY_PROJECT_NAME}
#ENV TEAMCITY_PROJECT_NAME=$TeamCityProjectName
#ENV TEAMCITY_PROJECT_NAME=${TEAMCITY_PROJECT_NAME}
RUN echo "TeamCityProjectName $TeamCityProjectName"
RUN echo "TEAMCITY_PROJECT_NAME $TEAMCITY_PROJECT_NAME"
RUN echo "{TEAMCITY_PROJECT_NAME} ${TEAMCITY_PROJECT_NAME}"

RUN dotnet test --verbosity=normal ./Tests/Tests.csproj

RUN dotnet publish ./AccountOwnerServer/AccountOwnerServer.csproj -o /publish/

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1

WORKDIR /publish

COPY --from=build-image /publish .

ENV ASPNETCORE_URLS="http://0.0.0.0:5000"
#ENV TEAMCITY_PROJECT_NAME=$TeamCityProjectName
##ENV TEAMCITY_PROJECT_NAME=${TEAMCITY_PROJECT_NAME}
#RUN echo "TeamCityProjectName $TeamCityProjectName"
#RUN echo "TEAMCITY_PROJECT_NAME $TEAMCITY_PROJECT_NAME"
#RUN echo "{TEAMCITY_PROJECT_NAME} ${TEAMCITY_PROJECT_NAME}"
#
ENTRYPOINT ["dotnet", "AccountOwnerServer.dll"]