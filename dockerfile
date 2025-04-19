# Sample DockerFile
# Use the official n8n Docker image
FROM n8nio/n8n

# Expose the default n8n port
EXPOSE 5678/tcp

# n8n configuration
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_PROTOCOL=http
ENV NODE_ENV=development
ENV N8N_SECURE_COOKIE=false

# Start n8n
CMD ["n8n", "start"]