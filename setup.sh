mkdir -p ~/repos
git clone git@github.com:romkatv/powerlevel10k.git ~/repos/powerlevel10k

if [ ! -f ~/.my_zshrc ]; then
  ln .my_zshrc ~/.my_zshrc
fi

if [ ! -f ~/.my_zshenv ]; then
  ln .my_zshenv ~/.my_zshenv
fi

if [ ! -f ~/.my_bashrc ]; then
  ln .my_bashrc ~/.my_bashrc
fi

if [ -f ~/.zshrc ] && [ `grep ". ~/.my_zshrc" ~/.zshrc | wc -l` == "0" ]; then
  echo ". ~/.my_zshrc" >> ~/.zshrc
fi

if [ -f ~/.zshenv ] && [ `grep ". ~/.my_zshenv" ~/.zshenv | wc -l` == "0" ]; then
  echo ". ~/.my_zshenv" >> ~/.zshenv
fi

if [ -f ~/.bashrc ] && [ `grep ". ~/.my_bashrc" ~/.bashrc | wc -l` == "0" ]; then
  echo ". ~/.my_bashrc" >> ~/.bashrc
fi