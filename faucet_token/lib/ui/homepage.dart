import 'package:flutter/material.dart';
//to use web3dart
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
//to connect metamask
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

//This code is nessesarry to use metamask instead of secret key.
class WalletConnectEthereumCredentials extends CustomTransactionSender {
  WalletConnectEthereumCredentials({required this.provider});

  final EthereumWalletConnectProvider provider;

  @override
  Future<EthereumAddress> extractAddress() {
    // TODO: implement extractAddress
    throw UnimplementedError();
  }

  @override
  Future<String> sendTransaction(Transaction transaction) async {
    final hash = await provider.sendTransaction(
      from: transaction.from!.hex,
      to: transaction.to?.hex,
      data: transaction.data,
      gas: transaction.maxGas,
      gasPrice: transaction.gasPrice?.getInWei,
      value: transaction.value?.getInWei,
      nonce: transaction.nonce,
    );

    return hash;
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) {
    // TODO: implement signToSignature
    throw UnimplementedError();
  }

  @override
  // TODO: implement address
  EthereumAddress get address => throw UnimplementedError();

  @override
  MsgSignature signToEcSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) {
    // TODO: implement signToEcSignature
    throw UnimplementedError();
  }
}

class _HomePageState extends State<HomePage> {
  //connect metamask using walletconnect_dart
  //Create a connector
  final connector = WalletConnect(
    bridge: 'https://bridge.walletconnect.org',
    clientMeta: const PeerMeta(
      name: 'WalletConnect',
      description: 'WalletConnect Developer App',
      url: 'https://walletconnect.org',
      icons: [
        'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
      ],
    ),
  );

  var _session, session, _uri;
  connectMetamaskWallet(BuildContext context) async {
    if (!connector.connected) {
      try {
        session = await connector.createSession(
            chainId: 5,
            onDisplayUri: (uri) async {
              _uri = uri;
              await launchUrlString(uri, mode: LaunchMode.externalApplication);
            });
        print(session.accounts[0]);
        setState(() {
          _session = session;
        });
      } catch (exp) {
        print(exp);
      }
    }
  }

  //send transaction using web3dart
  late Client httpClient;
  late Web3Client ethClient;
  //change this to your Infura goerli endpoints
  final String blockchainUrl =
      "https://goerli.infura.io/v3/0170d757246f418f999960b7f36484f1";

  var tokenBalance;

  @override
  void initState() {
    httpClient = Client();
    ethClient = Web3Client(blockchainUrl, httpClient);
    super.initState();
  }

  Future<DeployedContract> getContract() async {
    //change this to your abi file.
    String abiFile = await rootBundle.loadString("assets/contract.json");
    //change this to your ContractAddress
    String contractAddress = "0xF49CE5D5f85A9f1f7eDe1a4150c86Db9D97b337F";
    final contract = DeployedContract(
        ContractAbi.fromJson(abiFile, "FaucetTestToken"),
        EthereumAddress.fromHex(contractAddress));

    return contract;
  }

  Future<List<dynamic>> callFunction(String name, List<dynamic> args) async {
    final contract = await getContract();
    final function = contract.function(name);
    final result = await ethClient.call(
        contract: contract, function: function, params: args);
    return result;
  }

  Future<void> getTokenBalance(String account) async {
    final userAddress = EthereumAddress.fromHex(account);
    List<dynamic> results = await callFunction("balanceOf", [userAddress]);
    setState(() {
      tokenBalance = (results[0] ~/ BigInt.from(pow(10, 18))).toInt();
    });
  }

  snackBar({String? label}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label!),
            CircularProgressIndicator(
              color: Colors.white,
            )
          ],
        ),
        duration: Duration(days: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> faucet(String account) async {
    snackBar(label: "move to metamask and verify.");
    final userAddress = EthereumAddress.fromHex(account);

    //obtain our contract from abi in json file
    final contract = await getContract();
    // extract function from json file
    final function = contract.function("faucet");
    //get secret key from metamask
    EthereumWalletConnectProvider provider =
        EthereumWalletConnectProvider(connector);
    //obtain private key for write operation
    final credentials = WalletConnectEthereumCredentials(provider: provider);
    //send transaction using the our private key, function and contract
    await ethClient.sendTransaction(
        credentials,
        Transaction.callContract(
            from: userAddress,
            contract: contract,
            function: function,
            parameters: [userAddress, BigInt.from(1)]),
        chainId: 5);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    snackBar(label: "verifying transaction");
    //set a 20 seconds delay to allow the transaction to be verified before trying to retrieve the balance
    Future.delayed(const Duration(seconds: 20), () {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      snackBar(label: "retrieving transaction");

      getTokenBalance(account);

      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  Widget build(BuildContext context) {
    var account = session?.accounts[0];
    var chainId = session?.chainId;

    return Scaffold(
      appBar: AppBar(
        title: Text('FaucetTest'),
      ),
      body: (session == null)
          //before connecting with wallet.
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Text(
                      "Please Click Button to Connect with metamask wallet application"),
                ),
                ElevatedButton(
                    onPressed: () {
                      connectMetamaskWallet(context);
                    },
                    child: Text("Connect wallet")),
              ],
            ))
          : (account != null)
              //after connecting with wallet.
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "You are connected!",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 30, width: 10),
                      Container(
                          padding: EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Your account is $account"),
                              SizedBox(height: 10, width: 10),
                              Text("Your chainId is $chainId"),
                            ],
                          )),
                      Container(
                        padding: EdgeInsets.all(30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "You have ${tokenBalance ?? "０"} FTT.",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 30, width: 20),
                            ElevatedButton(
                              onPressed: () {
                                getTokenBalance(account);
                              },
                              child: Text('Reload'),
                            ),
                            SizedBox(height: 30, width: 20),
                            ElevatedButton(
                              onPressed: () {
                                faucet(account);
                              },
                              child: Text('Get a Token!'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              //if you can't connect with wallet by error.
              : Text("No account"),
    );
  }
}
