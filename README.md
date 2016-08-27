# docker-phoenix-dev
Apache Phoenix with remote-debugging in Docker for Phoenix development

## Usage

### Build
Docker 1.10 or higher is required to build the image (to use `--build-arg`).

To debug your own fork
```
docker build -t kliew/phoenix-dev --build-arg REPO=https://github.com/kliewkliew/phoenix .
```

To build a specific revision
```
docker build -t kliew/phoenix-dev --build-arg REPO=https://github.com/kliewkliew/phoenix --build-arg REVISION=PHOENIX-2641 .
```

You may have to build with `--no-cache`  but in most cases you can just specify the revision to use the cache up until the `git clone ~` step, after which the build process will do `git pull` and checkout the specified revision.


#### Build Parameters
* REPO         Phoenix git fork 
* REVISION     Git revision of $REPO
* APACHE_MIRROR       Choose a mirror for downloading Zookeeper, HBase from http://www.apache.org/mirrors/dist.html.

### Run
```
docker run -it -p $HOST_DEBUG_PORT:9999 kliew/hive-dev
```
Add `-p 8765:8765` if you want access from an external thin client.

In Eclipse, open Debug Configurations, create Remote Java Application, Host: localhost, Port: $HOST_DEBUG_PORT.
