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

var
l = instance_create(0, 0, obServerClient);
l.socket_id = socket_id;
l.client_id = client_id_counter++;

// loops through client_id possible values
if (client_id_counter >= 65000) {

    client_id_counter = 0;

}

// adds to clientmap
clientmap[? string(socket_id)] = l;

buffer_seek(send_buffer, buffer_seek_start, 0);
buffer_write(send_buffer, buffer_u8, MESSAGE_GETID);
buffer_write(send_buffer, buffer_u16, l.client_id);
network_send_raw(socket_id, send_buffer, buffer_tell(send_buffer));

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
            // read client x,y
            var
            xx = buffer_read(buffer, buffer_u16);
            yy = buffer_read(buffer, buffer_u16);
            
            clientObject.x = xx;
            clientObject.y = yy;
            
            // send data
            // reset byte counter
            buffer_seek(send_buffer, buffer_seek_start, 0); 
            buffer_write(send_buffer, buffer_u8, MESSAGE_MOVE);
            buffer_write(send_buffer, buffer_u16, client_id_current);
            buffer_write(send_buffer, buffer_u16, xx);
            buffer_write(send_buffer, buffer_u16, yy);
            
            with (obServerClient) {
                // dont send client1 data back to client1
                if (client_id != client_id_current) {
                    // self and other
                    network_send_raw(self.socket_id, other.send_buffer, buffer_tell(other.send_buffer));
                
                }
            
            }
            
        
        break;
        
        case MESSAGE_SHOOT:
        
            var
            shootdirection = buffer_read(buffer, buffer_u16);
            
            server_handle_shoot(shootdirection, clientObject);
        
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

buffer_seek(send_buffer, buffer_seek_start, 0);
buffer_write(send_buffer, buffer_u8, MESSAGE_LEAVE);
buffer_write(send_buffer, buffer_u16, clientmap[? string(socket_id)].client_id);

with (clientmap[? (string(socket_id))]) {

    instance_destroy();

}

ds_map_delete(clientmap, string(socket_id));

with (obServerClient) {

    network_send_raw(self.socket_id, other.send_buffer, buffer_tell(other.send_buffer));

}

#define server_handle_shoot
///server_handle_shoot(shootdirection, clientObject)

var
shootdirection = argument0,
tempObject = argument1,
hit = false,
obj = noone,
// the number is the number of pixels we want to map to (smaller =  more precise)
scan_length = 10;

var
prx = tempObject.x, // previous x
pry = tempObject.y, // previous y
prog = 0, // progress
tox = prx, // to x
toy = pry; // to y

with (tempObject) {

    while (prog < SHOOT_RANGE) {

        tox = prx + lengthdir_x(scan_length, shootdirection);
        toy = pry + lengthdir_y(scan_length, shootdirection);
        obj = collision_line(prx, pry, tox, toy, all, false, true);
        if (instance_exists(obj)) {
            //hit
            hit = true;
            prog += scan_length;
            break;
        
        }
        
        prx = tox;
        pry = toy;
        prog += scan_length;
    
    }

}

if (hit) { // hit

    buffer_seek(send_buffer, buffer_seek_start, 0);
    buffer_write(send_buffer, buffer_u8, MESSAGE_HIT);
    buffer_write(send_buffer, buffer_u16, tempObject.client_id);
    buffer_write(send_buffer, buffer_u16, obj.client_id);
    buffer_write(send_buffer, buffer_u16, shootdirection);
    buffer_write(send_buffer, buffer_u16, prog);
    
    with (obServerClient) {
    
        network_send_raw(self.socket_id, other.send_buffer, buffer_tell(other.send_buffer));
    
    }

} else { // miss

    buffer_seek(send_buffer, buffer_seek_start, 0);
    buffer_write(send_buffer, buffer_u8, MESSAGE_MISS);
    buffer_write(send_buffer, buffer_u16, tempObject.client_id);
    buffer_write(send_buffer, buffer_u16, shootdirection);
    buffer_write(send_buffer, buffer_u16, prog);
    
    with (obServerClient) {
    
        network_send_raw(self.socket_id, other.send_buffer, buffer_tell(other.send_buffer));
    
    }

}