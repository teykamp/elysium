#define client_connect
///client_connect(ip, port)

var
ip = argument0,
port = argument1;

socket = network_create_socket(network_socket_tcp);
var connect = network_connect_raw(socket, ip, port);

send_buffer = buffer_create(256, buffer_fixed, 1);

clientmap = ds_map_create();

if (connect < 0) show_error("can't connect to server", true);

#define client_disconnect
///client_disconnect()

ds_map_destroy(clientmap);
network_destroy(socket);

#define client_handle_message
///client_handle_message(buffer)

var
buffer = argument0;

while (true) {
    // buffer_u8 = unsigned 8bit integer (smaller is better for faster transmission)
    var message_id = buffer_read(buffer, buffer_u8);
    
    switch(message_id) {
    
        case MESSAGE_MOVE:
        // must be same order as server side
            var client = buffer_read(buffer, buffer_u16);
            xx = buffer_read(buffer, buffer_u16);
            yy = buffer_read(buffer, buffer_u16);
            // received message from this client before?
            if (ds_map_exists(clientmap, string(client))) {
                // move object if seen before
                var clientObject = clientmap[? string(client)];
                clientObject.x = xx;
                clientObject.y = yy;
                
            } else {
                //create 
                var l = instance_create(xx, yy, oOtherClient);
                clientmap[? string(client)] = l
            
            }
            
            //send to server
            with (oServerClient) {
                // dont send to self
                if (client_id !=client_id_current) {
                
                    network_send_raw(self.socket_id, other.send_buffer, buffer_tell(other.send_buffer));
                
                }
            
            }
        
        break;
    
    }
    // buffer > 256 bytes?
    if (buffer_tell(buffer) == buffer_get_size(buffer)) {
    
        break;
    
    }
    
}

#define client_send_movement
///client_send_movement()

// start at beginning of buffer
buffer_seek(send_buffer, buffer_seek_start, 0);

buffer_write(send_buffer, buffer_u8, MESSAGE_MOVE);
// must send int, not float
buffer_write(send_buffer, buffer_u16, round(oPlayer.x));
buffer_write(send_buffer, buffer_u16, round(oPlayer.y));

network_send_raw(socket, send_buffer, buffer_tell(send_buffer));