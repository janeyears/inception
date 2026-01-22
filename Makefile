NAME = inception

all:
	# Create volume directories if they don't exist
	mkdir -p /home/ekashirs/data/mariadb
	mkdir -p /home/ekashirs/data/wordpress

	# Start Docker containers
	docker-compose -f srcs/docker-compose.yml up -d --build

down:
	docker-compose -f srcs/docker-compose.yml down

fclean:
	docker-compose -f srcs/docker-compose.yml down -v --remove-orphans || true
	docker system prune -af
	sudo rm -rf /home/ekashirs/data/mariadb
	sudo rm -rf /home/ekashirs/data/wordpress

re: fclean all

.PHONY: all down re fclean
