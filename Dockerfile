FROM mcr.microsoft.com/dotnet/core/sdk:3.1 as build-image

WORKDIR /home/app

COPY ./*.sln ./
COPY ./*/*.csproj ./
RUN for file in $(ls *.csproj); do mkdir -p ./${file%.*}/ && mv $file ./${file%.*}/; done

RUN dotnet restore

COPY . .

# ��� ������ ������ � ������������ xUnit ������������� �� �������� ���������� ���������
# TEAMCITY_PROJECT_NAME, ������� ������ ���� �������� �� TeamCity. ����� ����������� �
# ������������� ����� ������ ������ � ���������� ��������� TEAMCITY_PROJECT_NAME �����
# ����������. Ÿ ����� �������� ��� �������� ��������� ������ ��� ������ ������ � ���������
# "Additional arguments for the command" ���� docker build:
#	--build-arg TEAMCITY_PROJECT_NAME='%env.TEAMCITY_PROJECT_NAME%'
# ���� �������� ����� ������ ��� � ���������� ��������� (TEAMCITY_PROJECT_NAME), �� �������
# �������������� ������������ ������ �� �����.
ARG TEAMCITY_PROJECT_NAME
# ����� xUnit ������� �������� � ������ ���������� �������� ������� ����������� �������� ��
#	--verbosity=normal
RUN dotnet test --verbosity=normal ./Tests/Tests.csproj

RUN dotnet publish ./AccountOwnerServer/AccountOwnerServer.csproj -o /publish/

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1

WORKDIR /publish

COPY --from=build-image /publish .

ENV ASPNETCORE_URLS="http://0.0.0.0:5000"

ENTRYPOINT ["dotnet", "AccountOwnerServer.dll"]