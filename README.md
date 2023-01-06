# Damominer
```shell
      _                       
     | |                      
   __| | __ _ _ __ ___   ___  
  / _` |/ _` | '_ ` _ \ / _ \ 
 | (_| | (_| | | | | | | (_) |
  \__,_|\__,_|_| |_| |_|\___/ 
  ```
                              

## Introduction

GPU optimization Miner for Aleo


## Disclaimer

[damominer.hk](https://www.damominer.hk/) & [damominer_github](https://github.com/damomine) are the only 2 officially maintained site for publishing information and new releases of damominer.


## Install

Running command below under `root` user:
```shell
wget https://raw.githubusercontent.com/damomine/aleominer/main/damominer.sh && chmod +x damominer.sh
./damominer.sh
```

The miner will be installed to `/.damominer/damominer`.

## Usage

Please refer to the usage help (`./damominer --help`):

If you didn't have an aleo account, use the following command to create one:

```shell 
./damominer --new-account
```

**Please remember to save the account private key and view key.** 

```shell
Private key: APrivateKey1zkp95v192bRWbotxuUi7owk7uG31Tdim5qD6nFphcUmNHUA
   View key: AViewKey1h5yPK4bEUKEmApg8VbY5J2xAP7Hcox71BrkSL3YyxJhR
    Address: aleo1hefv5vr5c0x0fw9drzdwegdd0jgnt7swwvggezng9amxs95elg9qktnwn3

```

Then start miner like:
```shell
./damominer --address <your address> --proxy <solo prover proxy> [OPTIONS] 
```

```shell
Options:
      --address <ADDRESS>  Specify the Aleo address. Note: Use your address as the prover address.
      --worker <WORKER>    Specify the worker name. Note: The name consists of numbers and letters and cannot exceed 15 characters in length
      --proxy <PROXY>      Specify the proxy server address
  -g, --gpu <GPU>          Specify the index of GPU. Specify multiple times to use multiple GPUs, example: -g 0 -g 1 -g 2. Note: Use all gpus if not specify.
  -o, --log <LOG>          Specify the log file
```

## GPU supports

- NVIDIA Turing GPU
- NVIDIA Ampere GPU

## API Reference
### miner status 
**Path：** /status

**Method：** GET

**Response:**

    {
      "code": 200,
      "data": {
        "online": false
      }
    }
    


### gpu miner info 
**Path：** /gpu

**Method：** GET

**Response:**

    {
	"code": 200,
	"data": {
		"gpus": [{
			"cclk": 1635, //graphics clock
			"ctmp": 74, // gpu temperature
			"device": "2060SU", //gpu device 
			"fan": 76, //fan
			"gmclk": 6801, //graphics memory clock
			"id": 0,
			"inval": 0, //invalid
			"mtmp": "89", //max temperature
			"power": 169, //power
			"proof": 0.0, //proof rate
			"statle": 0, // statle
			"valid": 0 // valid
		}],
		"uptime": 197 //program up time 
	}
**Usage:**
```shell
./damominer --address <your address> --rest --port 5001 --proxy <solo prover proxy> [OPTIONS]    
```

## Changelog
### 1.1.0
support for aleo testnet3 phase2.   

### 1.2.0
merge code.

### 1.3.0
fix some issue.

### 1.4.0
fix some issue.

### 1.5.2
increase connect stabel.

### 1.6.1
support V100,A100
increase stalbel

### 2.0.0
increase performance

### 2.1.2
support 40-series cards<br>
enhance cuda performance<br>
decrease CPU load<br>
fix some issue (log crash, etc)

### 2.2.0
enhance performance<br>
add more log (driver verion, worker name, etc)<br>
support for using local time as log message timestamps

### 2.2.4
Optimize 20 series GPU performance for more than 10%, 30 series GPU performance for 15%, decrease the CPU requirements<br>
Shift from different proxies automatically<br>
Support Miner API, facilitating cluster management and monitor tools

### 2.3.0 and 2.3.1
GPU performance: Optimize mid-to-high-end GPU performance for more than 20%, low-end GPU performance for more than 15%.<br>
CPU requirement: the algorithm has been reconstructed, the CPU consumption has been largely reduced to the 30%-40% of the previous version.<br>
Note that v2.3.1 has relatively higher consumption of vRam which can result in the overload of 10G vRam in some operating system. In that case, please choose v2.3.0 to lower vRam load.
