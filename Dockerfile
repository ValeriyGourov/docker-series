FROM mcr.microsoft.com/dotnet/sdk:8.0 as build-image

EXPOSE 8080

WORKDIR /home/app

COPY ./*.sln ./
COPY ./*/*.csproj ./
RUN for file in $(ls *.csproj); do mkdir -p ./${file%.*}/ && mv $file ./${file%.*}/; done

RUN dotnet restore

COPY . .

# Для вывода данных о тестировании xUnit ориентируется на значение переменной окружения
# TEAMCITY_PROJECT_NAME, которое должно быть передано из TeamCity. Тесты запускаются в
# промежуточном этапе сборки образа и переменная окружения TEAMCITY_PROJECT_NAME здесь
# недоступна. Её нужно передать как аргумент комендной строки при сборке образа в параметре
# "Additional arguments for the command" шага docker build:
#	--build-arg TEAMCITY_PROJECT_NAME='%env.TEAMCITY_PROJECT_NAME%'
# Если аргумент будет назван как и переменная окружения (TEAMCITY_PROJECT_NAME), то никаких
# дополнительных телодвижений делать не нужно.
ARG TEAMCITY_PROJECT_NAME

# Чтобы xUnit выводил сведения о тестах необходимо повысить уровень подробности сведений до
#	--verbosity=normal
RUN dotnet test --verbosity=normal ./Tests/Tests.csproj
#RUN if [ ! -z "${TEAMCITY_PROJECT_NAME}" ]; then \
## Чтобы xUnit выводил сведения о тестах необходимо повысить уровень подробности сведений до
##	--verbosity=normal
#RUN dotnet test --verbosity=normal ./Tests/Tests.csproj; \
	#fi
#
RUN dotnet publish ./AccountOwnerServer/AccountOwnerServer.csproj -o /publish/

FROM mcr.microsoft.com/dotnet/aspnet:8.0

RUN apt-get update \
	&& apt-get install -y curl

# Решение проблемы "SSL Handshake failed with OpenSSL error - SSL_ERROR_SSL" при подключении к MySQL.
RUN sed -i '1i openssl_conf = default_conf' /etc/ssl/openssl.cnf && echo -e "\n[ default_conf ]\nssl_conf = ssl_sect\n[ssl_sect]\nsystem_default = system_default_sect\n[system_default_sect]\nMinProtocol = TLSv1\nCipherString = DEFAULT:@SECLEVEL=1" >> /etc/ssl/openssl.cnf

WORKDIR /publish

COPY --from=build-image /publish .

ENTRYPOINT ["dotnet", "AccountOwnerServer.dll"]