clear
check_tool() {
  REQUIRED_PKG="inotify-tools"
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
  echo Checking for dependencies: $PKG_OK
  if [ "" = "$PKG_OK" ]; then
    echo "No dependecies. Setting up dependecies."
    sudo apt-get --yes install $REQUIRED_PKG 
  fi
}
check_tool

path=$1
shift
cmd=$*
md5=0
update_md5() {
  md5=`ls -lR --time-style=full-iso $path | md5sum`
}
update_md5
previous_md5=$md5
build() {
  echo -en " \n[+] Building...\n\n"
  $cmd
  echo -en "\n--> Resumed watching."
}
compare() {
  update_md5
  if [[ $md5 != $previous_md5 ]] ; then
    echo -en "\n\n[!]Changes detected!\n\n"
    inotifywait -r * | tee -a log.txt
    build
    previous_md5=$md5
  else
    echo -n .
  fi
}
trap build SIGINT
trap exit SIGQUIT

echo -e  "--> Press Ctrl+C to force build, Ctrl+\\ to exit."
echo -en "--> watching \"$path\"."
while true; do
  compare
  sleep 1
done