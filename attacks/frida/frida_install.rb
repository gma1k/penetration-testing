#!/usr/bin/env ruby

require 'open-uri'
require 'json'

def get_parch
  `adb shell getprop ro.product.cpu.abi`.chomp
end

def download_frida(parch, url)
  puts "Downloading #{url}..."
  open(url) do |file|
    File.write("frida-server.xz", file.read)
  end
  puts "Extracting frida-server.xz..."
  system("unxz frida-server.xz")
end

def run_frida
  puts "Restarting adbd with root permissions..."
  system("adb root")
  puts "Pushing frida-server to the device..."
  system("adb push frida-server /data/local/tmp/frida-server")
  puts "Making frida-server executable..."
  system("adb shell chmod 755 /data/local/tmp/frida-server")
  puts "Running frida-server in the background..."
  system("adb shell /data/local/tmp/frida-server &")
end

parch = get_parch

parch = "arm" if parch == "armeabi-v7a"

url = JSON.parse(open("https://api.github.com/repos/frida/frida/releases").read)[0]["assets"].select { |asset| asset["browser_download_url"] =~ /server.*android-#{parch}\.xz/ }[0]["browser_download_url"]

puts "Do you want to download and run frida-server on your device? (y/n) "
answer = gets.chomp

if answer == "y"
  download_frida(parch, url)
  run_frida
  puts "Frida-server is running on your device."
else
  puts "Frida-server is not downloaded or running on your device."
end
