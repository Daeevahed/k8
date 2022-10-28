timedatectl set-timezone Asia/Tehran
hostnamectl set-hostname 
#swap off /rtc/fstab
#ip static






####install containerd

wget https://github.com/containerd/containerd/releases/download/v1.6.2/containerd-1.6.2-linux-amd64.tar.gz
sudo tar Czxvf /usr/local containerd-1.6.2-linux-amd64.tar.gz

####systemd service

wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mv containerd.service /usr/lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl status containerd

####install runc

wget https://github.com/opencontainers/runc/releases/download/v1.1.1/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc


####install configure

sudo mkdir -p /etc/containerd/
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

####Install CNI Plugin

mkdir -p /opt/cni/bin
wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz



###cgroup driver: 
####To use the systemd cgroup driver in /etc/containerd/config.toml with runc, set:
###[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc] ... [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options] SystemdCgroup = true
#####Forwarding IPv4 and letting iptables see bridged traffic:
#####https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd

######Forwarding IPv4 and letting iptables see bridged traffic

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

####################################Install Kubelet , Kubeadm and Kubectl:


sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


#####for init on master it`s mean that we should initialize master `
Sudo kubeadm init

##after installation conpleted on MASTER and initialed kubeadm!!!
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

###apply calico  on master
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

###taint on master
kubectl taint nodes --all node-role.kubernetes.io/control-plane




########### install nerdtcl full 64amd last ver     extract on /usr/local
wget https://github.com/containerd/nerdctl/releases/download/v0.22.2/nerdctl-full-0.22.2-linux-amd64.tar.gz
tar Cxzvvf /usr/local nerdctl-full-0.22.2-linux-amd64.tar.gz

####for join workers must create frist on master and run on worker
kubeadm token create --print-join-command

