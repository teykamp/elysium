#define server_create
///server_create(port)

var 
port = argument0,
server = 0;

server = network_create_server_raw(network_socket_tcp, port, 20);
clientmap = ds_map_create();
client_id_counter = 0;

send_buffer = buffer_create(256, buffer_fixed, 1);

if (server < 0) show_error("can't create server", true);

return server;


#define server_handle_connect
///server_handle_connect(socket_id);

var
socket_id = argument0;

l = instance_create(0, 0, obServerClient);
l.socket_id = socket_id;
l.client_id = client_id_counter++;

// loops through client_id possible values
if (client_id_counter >= 65000) {

    client_id_counter = 0;

}

// adds to clientmap
clientmap[? string(socket_id)] = l;

#define server_handle_message
///server_handle_meessage(socket_id, buffer);

var
socket_id = argument0,
buffer = argument1,
client_id_current = clientmap[? string(socket_id)].client_id;

// important part where code changes based on game type
// server knows whats happening (send thru message_id)

while (true) {
    // buffer_u8 = unsigned 8but integer (smaller is better for faster transmission)
    var message_id = buffer_read(buffer, buffer_u8);
    
    switch(message_id) {
    
        case MESSAGE_MOVE:
            // read client x,y,rot
            var
            xx = buffer_read(buffer, buffer_u16);
            yy = buffer_read(buffer, buffer_u16);
            rot = buffer_read(buffer, buffer_u16);
            
            // send data
            // reset byte counter
            buffer_seek(send_buffer, buffer_seek_start, 0); 
            buffer_write(send_buffer, buffer_u8, MESSAGE_MOVE);
            buffer_write(send_buffer, buffer_u16, client_id_current);
            buffer_write(send_buffer, buffer_u16, xx);
            buffer_write(send_buffer, buffer_u16, yy);
            buffer_write(send_buffer, buffer_u16, rot);
            
            with (obServerClient) {
                // dont send client1 data back to client1
                if (client_id != client_id_current) {
                    // self and other
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

#define server_handle_disconnect
///server_handle_disconnect(socket_id);

var
socket_id = argument0;

with (clientmap[? (string(socket_id))]) {

    instance_destroy();

}

ds_map_delete(clientmap, string(socket_id));
