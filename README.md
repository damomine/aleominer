# Damominer

      _                       
     | |                      
   __| | __ _ _ __ ___   ___  
  / _` |/ _` | '_ ` _ \ / _ \ 
 | (_| | (_| | | | | | | (_) |
  \__,_|\__,_|_| |_| |_|\___/ 
                              
                              

## Introduction

GPU optimization Miner for Aleo


## Disclaimer

[damominer.hk](https://www.damominer.hk/) & [damominer_github](https://github.com/damominer) are the only 2 officially maintained site for publishing information and new releases of damominer.



## Usage

Please refer to the usage help (`./damominer --help`):


If you didn't have an aleo account, use the following command to create one:
    ./damominer --new-account

**Please remember to save the account private key and view key.** 

Private key: APrivateKey1zkp95v192bRWbotxuUi7owk7uG31Tdim5qD6nFphcUmNHUA
   View key: AViewKey1h5yPK4bEUKEmApg8VbY5J2xAP7Hcox71BrkSL3YyxJhR
    Address: aleo1hefv5vr5c0x0fw9drzdwegdd0jgnt7swwvggezng9amxs95elg9qktnwn3



Then start miner like:
    ./damominer --address <your address> --pool <solo prover proxy> [OPTIONS] 

Options:
      --address <ADDRESS>  Specify the Aleo address. Note: Use your address as the prover address.
      --worker <WORKER>    Specify the worker name. Note: The name consists of numbers and letters and cannot exceed 15 characters in length
      --proxy <PROXY>      Specify the proxy server address
  -g, --gpu <GPU>          Specify the index of GPU. Specify multiple times to use multiple GPUs, example: -g 0 -g 1 -g 2. Note: Use all gpus if not specify.
  -o, --log <LOG>          Specify the log file


## GPU supports

NVIDIA Turing GPU
NVIDIA Ampere GPU

## Changelog

### 1.1.0
support for aleo testnet3 phase2.   
