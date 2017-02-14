# Test des connexions WebSocket

Utilisation de l'outil [wscat](https://github.com/jnordberg/wscat/releases/tag/1.1.0) en v1.1.0.

Ouverture d'une connexion WebSocket avec keepalive tous les 30 secondes~:

```
$ ./wscat --connect ws://openresty.example.com/sockjs/527/6_l78edj/websocket --keepalive 30
```

Rechargement de la configuration~:

```
$ SCALINGO_API_URL=https://api.example.com scalingo --app sample-ruby-sinatra restart
```

Voir l'état des processus~:

```
$ ps aux | grep nginx
```
