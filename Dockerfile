FROM eclipse-temurin:17-jre
WORKDIR /server
COPY . /server
RUN sed -i 's/\r$//' /server/entrypoint.sh \
 && chmod +x /server/entrypoint.sh \
 && echo "eula=true" > /server/eula.txt
ENV PORT=8000
EXPOSE 8000
ENTRYPOINT ["/server/entrypoint.sh"]
