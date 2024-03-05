# Kubeadm

# Подготовим ноды

# Отключим своп
```shell
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
```


# Сетевая настройка
```shell
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf<<EOF
net.bridge.bridge-nf-calliptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
```

```shell
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
```

# Установим контейнеры и исполняемые файлы kubernetes
```shell
sudo apt-get install -y containerd
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir /etc/apt/keyrings && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl

sudo kubeadm init --pod-network-cidr=10.129.0.0/16 --upload-certs --kubernetes-version=v1.27.0 --ignore-preflight-errors=Mem --cri-socket /run/containerd/containerd.sock
```

# Инициализируем kubernetes на master1
```shell
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.129.0.14:6443 --token 3aojn1.yultf8cvtxks531n \
        --discovery-token-ca-cert-hash sha256:09475fcb308a0f92a0c5e1a6be4f3557c5d51f7dd5b60c5e1ede064aae6258fc 
```

# Добавим ноды в кластер
```shell
sudo kubeadm join 10.129.0.14:6443 --token 3aojn1.yultf8cvtxks531n         --discovery-token-ca-cert-hash sha256:09475fcb308a0f92a0c5e1a6be4f3557c5d51f7dd5b60c5e1ede064aae6258fc
```

# Настроим пользование кластером
```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
```

# Кластер
```shell
kubectl get nodes
NAME      STATUS   ROLES           AGE    VERSION
master1   Ready    control-plane   5m9s   v1.27.11
worker1   Ready    <none>          82s    v1.27.11
worker2   Ready    <none>          43s    v1.27.11
worker3   Ready    <none>          33s    v1.27.11
```

```shell
kubectl apply -f deployment.yaml
deployment.apps/nginx-deployment created
eugen@master1:~$ kubectl get all
NAME                                    READY   STATUS              RESTARTS   AGE
pod/nginx-deployment-57d84f57dc-jkqvt   0/1     ContainerCreating   0          9s
pod/nginx-deployment-57d84f57dc-mb6kp   0/1     ContainerCreating   0          9s
pod/nginx-deployment-57d84f57dc-vh7t9   0/1     ContainerCreating   0          9s
pod/nginx-deployment-57d84f57dc-xkxkt   0/1     ContainerCreating   0          9s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   7m37s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   0/4     4            0           9s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-57d84f57dc   4         4         0       9s
```

# Обновляем версию кластера
```shell
sudo rm -rf /etc/apt/keyrings/kubernetes-apt-keyring.gpg && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl
```

# На master
```shell
sudo kubeadm upgrade plan
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks.
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: v1.27.0
[upgrade/versions] kubeadm version: v1.28.7
I0305 13:53:22.316313   34746 version.go:256] remote version is much newer: v1.29.2; falling back to: stable-1.28
[upgrade/versions] Target version: v1.28.7
[upgrade/versions] Latest version in the v1.27 series: v1.27.11

Upgrade to the latest version in the v1.27 series:

COMPONENT                 CURRENT    TARGET
kube-apiserver            v1.27.0    v1.27.11
kube-controller-manager   v1.27.0    v1.27.11
kube-scheduler            v1.27.0    v1.27.11
kube-proxy                v1.27.0    v1.27.11
CoreDNS                   v1.10.1    v1.10.1
etcd                      3.5.10-0   3.5.10-0

You can now apply the upgrade by executing the following command:

        kubeadm upgrade apply v1.27.11

_____________________________________________________________________

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT        TARGET
kubelet     4 x v1.27.11   v1.28.7

Upgrade to the latest stable version:

COMPONENT                 CURRENT    TARGET
kube-apiserver            v1.27.0    v1.28.7
kube-controller-manager   v1.27.0    v1.28.7
kube-scheduler            v1.27.0    v1.28.7
kube-proxy                v1.27.0    v1.28.7
CoreDNS                   v1.10.1    v1.10.1
etcd                      3.5.10-0   3.5.10-0

You can now apply the upgrade by executing the following command:

        kubeadm upgrade apply v1.28.7

_____________________________________________________________________


The table below shows the current state of component configs as understood by this version of kubeadm.
Configs that have a "yes" mark in the "MANUAL UPGRADE REQUIRED" column require manual config upgrade or
resetting to kubeadm defaults before a successful upgrade can be performed. The version to manually
upgrade to is denoted in the "PREFERRED VERSION" column.

API GROUP                 CURRENT VERSION   PREFERRED VERSION   MANUAL UPGRADE REQUIRED
kubeproxy.config.k8s.io   v1alpha1          v1alpha1            no
kubelet.config.k8s.io     v1beta1           v1beta1             no
```

```shell
sudo kubeadm upgrade apply v1.28.7
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.28.7". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```

# master1 обновлён, нужно перезагрузить kubelet
```shell
eugen@master1:~$ kubectl get node -o wide
NAME      STATUS   ROLES           AGE    VERSION    INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
master1   Ready    control-plane   135m   v1.27.11   10.129.0.14   <none>        Ubuntu 20.04.6 LTS   5.4.0-172-generic   containerd://1.7.2
worker1   Ready    <none>          131m   v1.27.11   10.129.0.25   <none>        Ubuntu 20.04.6 LTS   5.4.0-172-generic   containerd://1.7.2
worker2   Ready    <none>          131m   v1.27.11   10.129.0.24   <none>        Ubuntu 20.04.6 LTS   5.4.0-172-generic   containerd://1.7.2
worker3   Ready    <none>          131m   v1.27.11   10.129.0.13   <none>        Ubuntu 20.04.6 LTS   5.4.0-172-generic   containerd://1.7.2
eugen@master1:~$ sudo systemctl restart kubelet
eugen@master1:~$ kubectl get node -o wide
NAME      STATUS   ROLES           AGE    VERSION    INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
master1   Ready    control-plane   135m   v1.28.7    10.129.0.14   <none>        Ubuntu 20.04.6 LTS   5.4.0-172-generic   containerd://1.7.2
worker1   Ready    <none>          132m   v1.27.11   10.129.0.25   <none>        Ubuntu 20.04.6 LTS   5.4.0-172-generic   containerd://1.7.2
worker2   Ready    <none>          131m   v1.27.11   10.129.0.24   <none>        Ubuntu 20.04.6 LTS   5.4.0-172-generic   containerd://1.7.2
worker3   Ready    <none>          131m   v1.27.11   10.129.0.13   <none>        Ubuntu 20.04.6 LTS   5.4.0-172-generic   containerd://1.7.2
```

# Проверяем версии на master
```shell
eugen@master1:~$ sudo kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"28", GitVersion:"v1.28.7", GitCommit:"c8dcb00be9961ec36d141d2e4103f85f92bcf291", GitTreeState:"clean", BuildDate:"2024-02-14T10:39:01Z", GoVersion:"go1.21.7", Compiler:"gc", Platform:"linux/amd64"}
eugen@master1:~$ sudo kubelet --version
Kubernetes v1.28.7
eugen@master1:~$ sudo kubectl version
Client Version: v1.28.7
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3

```

# Обновляем worker-ноды
```shell
eugen@master1:~$ kubectl drain worker1 --ignore-daemonsets
node/worker1 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-flannel/kube-flannel-ds-s82f2, kube-system/kube-proxy-rhp76
evicting pod default/nginx-deployment-57d84f57dc-xkxkt
evicting pod default/nginx-deployment-57d84f57dc-mb6kp
pod/nginx-deployment-57d84f57dc-mb6kp evicted
pod/nginx-deployment-57d84f57dc-xkxkt evicted
node/worker1 drained
```

```shell
eugen@worker1:~$ sudo kubeadm upgrade node
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks
[preflight] Skipping prepull. Not a control plane node.
[upgrade] Skipping phase. Not a control plane node.
[upgrade] Backing up kubelet config file to /etc/kubernetes/tmp/kubeadm-kubelet-config2251459348/config.yaml
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade] The configuration for this node was successfully updated!
[upgrade] Now you should go ahead and upgrade the kubelet package using your package manager.

sudo systemctl restart kubelet
```

# Возращаем worker1 в работу
```shell
eugen@master1:~$ kubectl uncordon worker1
node/worker1 uncordoned
```

В итоге имеем
```shell
eugen@master1:~$ kubectl get nodes
NAME      STATUS   ROLES           AGE    VERSION
master1   Ready    control-plane   159m   v1.28.7
worker1   Ready    <none>          155m   v1.28.7
worker2   Ready    <none>          154m   v1.28.7
worker3   Ready    <none>          154m   v1.28.7
```

# Kubespray

# Подготовим ноды, создадим доступ с гостейвой ВМ на 5 нод
```shell
sudo swapoff -a && sudo ufw disable && sudo systemctl disable ufw
sudo apt-get install software-properties-common -y
sudo apt update -y
sudo apt upgrade -y
sudo apt install aufs-tools -y
sudo apt install python3-pip -y
sudo apt-get install build-essential libssl-dev libffi-dev python-dev -y
sudo apt-get update -y
```

# Установим kubespray
```shell
git clone https://github.com/kubernetes-sigs/kubespray.git
sudo apt-get install -y python3-venv
VENVDIR=kubespray-venv
sudo python3 -m venv $VENVDIR
source $VENVDIR/bin/activate
```

# Настроим kuberspray
```shell
cd kubespray
pip install -U -r requirements.txt
cp -rfp inventory/sample inventory/eugen
vi inventory/eugen/inventory.ini
cat inventory/eugen/inventory.ini
[all]
master1 ip=10.129.0.14  etcd_member_name=etcd1
master2 ip=10.129.0.25  etcd_member_name=etcd2
master3 ip=10.129.0.24  etcd_member_name=etcd3
worker1 ip=10.129.0.13  etcd_member_name=etcd4
worker2 ip=10.3.0.5     etcd_member_name=etcd5

[kube_control_plane]
master1
master2
master3

[etcd]
master1
master2
master3

[kube_node]
worker1
worker2

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
```

# Установим кластер
```shell
ansible-playbook -i inventory/eugen/inventory.ini --become --become-user=root --user=${SSH_USERNAME} --key-file=${SSH_PRIVATE_KEY} cluster.yml
```

# Результат
```shell
kubectl get nodes
NAME       STATUS   ROLES           AGE   VERSION
master1    Ready    control-plane   54m   v1.28.7
master2    Ready    control-plane   54m   v1.28.7
master3    Ready    control-plane   54m   v1.28.7
worker1    Ready    <none>          47m   v1.28.7
worker2    Ready    <none>          47m   v1.28.7
```