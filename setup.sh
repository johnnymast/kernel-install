#!/bin/bash

# Define the base URL for kernel.org
base_url="https://www.kernel.org/"

# Fetch the latest kernel versions
latest_versions=$(curl -s $base_url | grep -oP 'strong>\K[0-9]+\.[0-9]+\.[0-9]+' | sort -Vr | uniq | head -n 5)

# Add the mainline version manually
mainline_version="6.13-rc1"

# Combine the versions into a single array
all_versions=("$mainline_version" $latest_versions)

# Display the latest kernel versions including the mainline
echo "Latest Linux kernel versions:"
select version in "${all_versions[@]}"; do
    if [ -n "$version" ]; then
        echo "You selected $version"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Parse the HTML for the tarball link containing the selected version
if [[ $version == *"-rc"* ]]; then
    tarball_url="https://git.kernel.org/torvalds/t/linux-$version.tar.gz"
else
    tarball_url=$(curl -s $base_url | grep -oP "href=\"[^\"]*linux-$version\.tar\.xz\"" | grep -oP 'href="\K[^"]*')
    tarball_url="https://cdn.kernel.org${tarball_url}"
fi



echo "Installing dependencies"
sudo pacman -S base-devel xmlto kmod inetutils bc libelf git

repository_dir=~/repos


if [ ! -d "$repository_dir" ]; then
    mkdir $repository_dir
fi

cd $repository_dir

echo "Downloading Linux kernel $version source..."
wget "$tarball_url"

echo "Download complete. You can now extract and compile the kernel."


# Determine the file extension and download the selected kernel version source
if curl -s --head --request GET ${base_url}linux-$version.tar.xz | grep "200 OK" > /dev/null; then
    file_extension="tar.xz"
else
    file_extension="tar.gz"
fi

echo "Downloading Linux kernel $version source..."
wget ${base_url}linux-$version.$file_extension

echo "Download complete."
echo "Extracting kernel sources."

tar fvxz "linux-$version.$file_extension" -C $repository_dir

echo "Removing tarball"
rm "linux-$version.$file_extension"

cd $repository_dir/linux-$version

echo "Cleaning kernel source"
make clean && make mrproper


choice=2

if [ -f "/proc/config.gz" ]; then
    echo "Select an option:"
    echo "1) Build using existing config file"
    echo "2) Generate config file based on connected hardware"
    read -p "Enter your choice [1-2]: " choice
else
    choice=2
fi


case $choice in
    1)
        echo "Building using existing config file..."
        zcat /proc/config.gz > .config
        make olddefconfig
        ;;
    2)
        echo "Generating config file based on connected hardware..."
        make localmodconfig
        ;;
    *)
        echo "Invalid choice. Please select 1 or 2."
        ;;
esac

echo "Running menu config"
make menuconfig



echo "Starting build"
make -j$(nproc)

if [ $? -eq 0 ]; then
    echo "Build completed successfully!"

    echo "Installing modules"
    sudo make modules_install

    echo "Installing kernel"
    sudo make install

    echo "copying arch/x86/boot/bzImage to /boot"
    sudo cp arch/x86/boot/bzImage /boot

    echo "copying vmlinux to /boot"
    sudo cp vmlinux /boot

    sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio-custom.conf
    sudo mkinitcpio --generate /boot/initrd-$version.img --kernel $version

else
    echo "Build failed. Please check the error messages above."
fi
