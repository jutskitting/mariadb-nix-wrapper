{
  description = "A Shell for a mysql server";

  inputs = {

    nixpkgs = {
	   url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    flake-utils.url  = "github:numtide/flake-utils";

  };

  outputs = { self, nixpkgs, flake-utils, }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            mariadb_110
          ];
            shellHook = ''
              echo "Setting up MariaDB environment..."
              export PATH=$PATH:$(dirname $(which mariadbd))

              DATABASE_DIR="$PWD/database"
              SOCKET_FILE="$DATABASE_DIR/mysqld.sock"
              PID_FILE="$DATABASE_DIR/mariadb.pid"

              # Ensure the database directory exists
              if [ ! -d "$DATABASE_DIR" ]; then
                echo "Initializing database directory..."
                mkdir -p "$DATABASE_DIR"
                mariadb-install-db --user=$(whoami) --basedir=$(dirname $(dirname $(which mariadb-install-db))) --datadir="$DATABASE_DIR"
              fi

              # Start MariaDB server if it's not running, using a custom socket file
              if ! pgrep -x mariadbd > /dev/null; then
                echo "MariaDB server not detected. Attempting to start..."
                mariadbd --datadir="$DATABASE_DIR" --socket="$SOCKET_FILE" --pid-file="$PID_FILE" &
                sleep 5 # Give the server time to start
              else
                echo "MariaDB server is already running."
              fi

              # Provide instructions for manual server management and setting the root password
              echo "Setup Complete. Use the following commands as needed:"
              echo "To start the server: mariadbd --datadir='$DATABASE_DIR' --socket='$SOCKET_FILE' &"
              echo "To stop the server: mariadb-admin shutdown --socket='$SOCKET_FILE'"

              # Ensure MariaDB server shuts down properly when exiting the shell
              trap "echo 'Stopping MariaDB server...'; mariadb-admin shutdown --socket='$SOCKET_FILE'" EXIT
            '';
        };
     }
    );
}


