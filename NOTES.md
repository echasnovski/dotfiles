# Managing passwords and personal access tokens (PAT)

This is mostly used for Github: using PATs and signing commits. Currently the preferred method is to use GnuPG and `pass`.

## Prerequisites

- [`gpg`](https://gnupg.org/download/) command line utility.
- [`pass`](https://www.passwordstore.org/) command line utility.

## Create GPG key

- Run `gpg --full-gen-key` and follow prompts. This will create a public/private key pair with all information stored in '~/.gnupg'. Use `gpg --list-keys` to see information about created keys.

## Use `pass`

- Run `pass insert <name>` to add password with "storage name" `<name>`.
- To insert multiline secret information (like combination of username, password, etc.) use `pass insert -m <name>` and enter in prompt.

## Use with Github

- To use Personal Access Token with 'pass' and GPG:
    - Create 'github' entry in 'pass' with Github's username and password (PAT). For this, run `pass insert -m github` and enter (replace `<username>` and `<password>` with user name and password (PAT):
    ```bash
    username=<username>
    password=<password>
    ```
    - Set Git's credential helper for Github. Add the following entry to appropriate ('~/.gitconfig' for global config, local to repository for local config) '.gitconfig' file:
    ```
    [credential "https://github.com"]
      helper = !pass github
    ```
- To sign commits:
    - Enable auto signing with `git config --global commit.gpgsign true`.
    - Then choose one option:
        - Create a GPG key that has identical information (name and email) as is set up in Git.
        - Or add global (or local with `--local` instead of `--global`) configuration with `git config --global user.signingkey <your_key_id>` where `<your_key_id>` is a preferred public key.
    - Add GPG key to Github account: [source](https://docs.github.com/en/github/authenticating-to-github/adding-a-new-gpg-key-to-your-github-account).

## Sources

- [Using GPG](https://www.youtube.com/watch?v=ZSa-d_9O5DA) Youtube video.
- [Github commit signing](https://docs.github.com/en/github/authenticating-to-github/managing-commit-signature-verification).
- [Git commit auto signing](https://gist.github.com/mort3za/ad545d47dd2b54970c102fe39912f305). Copy:
    ```bash
    # Generate a new pgp key: (better to use gpg2 instead of gpg in all below commands)
    gpg --gen-key
    # maybe you need some random work in your OS to generate a key. so run this command: `find ./* /home/username -type d | xargs grep some_random_string > /dev/null`

    # check current keys:
    gpg --list-secret-keys --keyid-format LONG

    # See your gpg public key:
    gpg --armor --export YOUR_KEY_ID
    # YOUR_KEY_ID is the hash in front of `sec` in previous command. (for example sec 4096R/234FAA343232333 => key id is: 234FAA343232333)

    # Set a gpg key for git:
    git config --global user.signingkey your_key_id

    # To sign a single commit:
    git commit -S -a -m "Test a signed commit"

    # Auto-sign all commits globally
    git config --global commit.gpgsign true
   ```

    And also one of the comments:
    ```bash
    # In case of error gpg: signing failed: Inappropriate ioctl for device
    # while signing a commit use `export GPG_TTY=$(tty)` in your ~/.bashrc or
    # ~/.zshrc file.

    # Cache your password for 1 day (86400 seconds) add file
    # '~/.gnupg/gpg-agent.conf' (for gpg 2) with

    default-cache-ttl 86400
    max-cache-ttl 86400

    # Reload gpg agent:
    gpgconf --reload gpg-agent
    ```

# Render Altair image outputs as PNG in Jupyter notebook

This originally was needed to post Jupyter notebook to Confluence directly (via `nbconflux`).

To render Altair image outpus as PND:

- Install https://github.com/altair-viz/altair_saver
- Install **globally** (`-g` flag) required packages by Node:

$ npm install -g vega-lite vega-cli canvas

- Also maybe anaconda install might be needed:

$ conda install -c conda-forge vega-cli vega-lite-cli

# Hide data from Jupyter Notebook cells during Confluence export

Cell hiding is done by adding tags "noinput", "nooutput", or "nocell" to specific cells. Unfortunately, currently (2020-04-08) this should be done manually by opening Jupyter Notebook in browser. To enable adding tags, in menu click "View"-"Cell Toolbar"-"Tags". Then, insert tag into field and **press "add tag" button"**.

# Set up Miniconda

Good source: https://medium.com/dunder-data/anaconda-is-bloated-set-up-a-lean-robust-data-science-environment-with-miniconda-and-conda-forge-b48e1ac11646

Summary of steps:

- Possibly [uninstall Anaconda](https://conda.io/projects/conda/en/latest/user-guide/install/linux.html#uninstalling-anaconda-or-miniconda):
    - Remove the entire Miniconda install directory with:

	rm -rf ~/anaconda3

    - OPTIONAL: Edit ~/.bash_profile to remove the Anaconda directory from your PATH environment variable (probably means removing all side-effects of "conda init").
    - OPTIONAL: Remove the following hidden file and folders that may have been created in the home directory: '.condarc' file, '.conda' directory, '.continuum' directory. Run:

        rm -rf ~/.condarc ~/.conda ~/.continuum

- Install Miniconda for your OS with the default settings
- Prevent the base environment from automatically activating:

    conda config --set auto_activate_base false

- Create an empty environment:

    conda create -n pydata

- Activate the environment:

    conda activate pydata

- Add conda-forge as the first channel:

    conda config --env --add channels conda-forge

- Ensure that conda-forge is used if the package is available:

    conda config --env --set channel_priority strict

- Install packages:

    conda install numpy pandas matplotlig scikit-learn ipython jupyter notebook

# Install R on Linux

Source: https://docs.rstudio.com/resources/install-r/

Here are steps for Ubuntu:

- Install required dependencies:

    sudo apt-get update
    sudo apt-get install gdebi-core

- Specify R version:

    export R_VERSION=4.0.0

- Download and install R

    curl -O https://cdn.rstudio.com/r/ubuntu-1804/pkgs/r-${R_VERSION}_1_amd64.deb
    sudo gdebi r-${R_VERSION}_1_amd64.deb

- Verify R installation

    /opt/R/${R_VERSION}/bin/R --version

- Create a symlink to R

    sudo ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R
    sudo ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Install R-devel from source

- Download and unpack .tar.gz version of R source from https://stat.ethz.ch/R/daily/.
- Follow https://support.rstudio.com/hc/en-us/articles/215488098-Installing-multiple-versions-of-R-on-Linux . Which is:
    - Ensure that you have the build dependencies required for R with

        sudo apt-get build-dep r-base

    - From unpacked R-devel directory run (change target directory in `--prefix` appropriately) (takes considerable amount of time):

        $ sudo ./configure --prefix=/opt/R/4.1.0-devel --enable-R-shlib
        $ sudo make
        $ sudo make install

# Kitty and images in ipython

Notes about quick exploration of possible setup to have inline images for 'ipython' when using kitty terminal emulator.

## Prerequisites

- Kitty terminal ([installation instructions](https://sw.kovidgoyal.net/kitty/binary.html)).
- Imagemagick ([installation instructions](https://www.tecmint.com/install-imagemagick-on-debian-ubuntu/)).
- 'imgcat' Python module with Kitty support. Currently it exists only as a [draft PR](https://github.com/wookayin/python-imgcat/pull/8). Install it with `python -m pip install git+https://github.com/wookayin/python-imgcat@kitty`.

## Usage

With this setup it should work from terminal itself. For example, this code snippet should result into inline image:

```python
import matplotlib
matplotlib.use("module://imgcat")
import matplotlib.pyplot as plt
plt.plot([0, 1], [0, 1])
plt.show()
```

## Notes

- Use environment variable to setup matplotlib backend. To do this, run (i)python with `MPLBACKEND="module://imgcat" (i)python`.
- This currently doesn't work inside Neovim terminal buffer. In fact, kitty's ['icat' kitten](https://sw.kovidgoyal.net/kitty/kittens/icat.html) doesn't work there (gives error 'Terminal does not support reporting screen sizes via the TIOCGWINSZ ioctl'). There is [this issue](https://github.com/neovim/neovim/issues/8259) in Neovim repository.
- It would be useful to also have inline images inside 'radian' for R. However, no actual exploration was done. Probably custom graphical device with radian startup hook should be enough.

# Set up Visidata

- Install [pipx](https://github.com/pipxproject/pipx).
- Install [visidata](https://www.visidata.org/) with `pipx install visidata`.
- Install optional dependencies for various data formats (see the list [here](https://raw.githubusercontent.com/saulpw/visidata/stable/requirements.txt)) with `pipx inject visidata ...`. Currently the preferred list of packages is installed with the following command:
    ```{bash}
    pipx inject visidata requests lxml openpyxl xlrd h5py psycopg2-binary xport savReaderWriter PyYAML
    ```

# Set up Canon LBP2900 printer on Ubuntu 18.04

Source: http://alligator.work/установка-принтера-canon-lbp2900-на-ubuntu-mint-18/

# Microphone is too quiet

Check microphone sensitivity with `pavucontrol`. Increase if necessary.
