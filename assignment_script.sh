#!/bin/bash

check_command_installed() {
  command -v "$1" >/dev/null 2>&1
}

install_docker() {
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker "$USER"
  sudo systemctl enable docker
}

install_docker_compose() {
  sudo curl -fsSL https://github.com/docker/compose/releases/latest/download/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
}

create_wordpress_site() {
  site_name="$1"
  mkdir "$site_name"
  cd "$site_name" || exit 1
  cat <<EOF > docker-compose.yml
version: '3'
services:
  db:
    image: mariadb
    restart: always
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: root
      MYSQL_PASSWORD: root
      MYSQL_ROOT_PASSWORD: root
    volumes:
      - db_data:/var/lib/mysql
  wordpress:
    depends_on:
      - db
    image: wordpress
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: root
    volumes:
      - ./wp-content:/var/www/html/wp-content
    ports:
      - "80:80"
volumes:
  db_data:
EOF

  docker-compose up -d

  echo "127.0.0.1 $site_name" | sudo tee -a /etc/hosts >/dev/null
}

enable_site() {
  site_name="$1"
  cd "$site_name" || exit 1
  docker-compose start
  echo "WordPress site '$site_name' enabled!"
}

disable_site() {
  site_name="$1"
  cd "$site_name" || exit 1
  docker-compose stop
  echo "WordPress site '$site_name' disabled!"
}

delete_site() {
  site_name="$1"
  cd "$site_name" || exit 1
  docker-compose down
  cd .. || exit 1
  rm -rf "$site_name"
  echo "WordPress site '$site_name' deleted!"
}

open_browser() {
  site_name="$1"
  xdg-open "http://$site_name"
}

main() {
  if ! check_command_installed "docker"; then
    echo "Docker not found. Installing Docker..."
    install_docker
  fi

  if ! check_command_installed "docker-compose"; then
    echo "Docker Compose not found. Installing Docker Compose..."
    install_docker_compose
  fi

  site_name="$2"
  action="$1"

  if [ "$action" = "create" ]; then
    create_wordpress_site "$site_name"
    echo "WordPress site '$site_name' created successfully!"
    open_browser "$site_name"
  elif [ "$action" = "enable" ]; then
    enable_site "$site_name"
  elif [ "$action" = "disable" ]; then
    disable_site "$site_name"
  elif [ "$action" = "delete" ]; then
    delete_site "$site_name"
  fi
}

main "$@"
