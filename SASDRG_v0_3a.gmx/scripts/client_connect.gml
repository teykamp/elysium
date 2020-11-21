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

buffer_seek(send_buffer, buffer_seek_start, 0);
buffer_write(send_buffer, buffer_u8, MESSAGE_GETID);
buffer_write(send_buffer, buffer_u16, l.client_id);
network_send_raw(socket_id, send_buffer, buffer_tell(send_buffer));

my_client_id = -1;

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
    
        case MESSAGE_GETID:
        
            my_client_id = buffer_read(buffer, buffer_u16);
        
        break;
    
        case MESSAGE_MOVE:
        // must be same order as server side
            var client = buffer_read(buffer, buffer_u16);
            xx = buffer_read(buffer, buffer_u16);
            yy = buffer_read(buffer, buffer_u16);
            clientObject = client_get_object(client);
            
            clientObject.x = xx;
            clientObject.y = yy;
        
        break;
        
        case MESSAGE_JOIN:
            // DO SOMETHING
        
        break;
        
        
        // delete player after disconnect
        case MESSAGE_LEAVE:
        
            var
            client = buffer_read(buffer, buffer_u16);
            tempObject = client_get_object(client);
        
            with (tempObject) 
                instance_destroy();
        
        break;
        
        case MESSAGE_HIT:
        
        var
        clientshootid = buffer_read(buffer, buffer_u16),
        clientshoot = client_get_object(clientshootid),
        clientshotid = buffer_read(buffer, buffer_u16),
        clientshot = client_get_object(clientshotid),
        shootdirection = buffer_read(bufer, buffer_u16),
        shootlength = buffer_read(buffer, buffer_u16),
        hit_x = clamp(clientshoot.x + lengthdir_x(shootlength, shootdirection), clientshot.x, clientshot.x + 16),
        hit_x = clamp(clientshoot.y + lengthdir_y(shootlength, shootdirection), clientshot.y, clientshot.y + 16);
        
        break;
        
        case MESSAGE_MISS:
        
        var
        clientshootid = buffer_read(buffer, buffer_u16),
        clientshoot = client_get_object(clientshootid),
        shootdirection = buffer_read(bufer, buffer_u16),
        shootlength = buffer_read(buffer, buffer_u16);
        
        break;
    
    } // end of switch (keep below all case statements)
        
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
buffer_write(send_buffer, buffer_u16, round(obPlayer.x));
buffer_write(send_buffer, buffer_u16, round(obPlayer.y));

network_send_raw(socket, send_buffer, buffer_tell(send_buffer));

#define client_get_object
///client_get_object(client_id)

var
client_id = argument0;

if (client_id = my_client_id) {

    if (!instance_exists(obPlayer))
        instance_create(0, 0, obPlayer);    

    return obPlayer.id;

}

// received message from this client before?
if (ds_map_exists(clientmap, string(client))) {
    // move object if seen before
    return clientObject = clientmap[? string(client)];
    
} else {
    //create 
    var l = instance_create(xx, yy, obOtherClient);
    clientmap[? string(client)] = l
    return l;

}

#define client_send_shoot
///client_send_shoot(direction)

var
dir = argument0;

buffer_seek(send_buffer, buffer_seek_start, 0);

buffer_write(send_buffer, buffer_u8, MESSAGE_SHOOT);
buffer_write(send_buffer, buffer_u16, dir);

network_send_raw(socket, send_buffer, buffer_tell(send_buffer));