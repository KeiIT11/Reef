import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
//to use listview from map
import 'dart:convert';
//to use web3dart
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
//to connect metamask
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'dart:math';

const String kFileName = 'myJsonFile.json';

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

class RecordView extends StatefulWidget {
  const RecordView({super.key});
  @override
  _RecordViewState createState() => _RecordViewState();
}

class _RecordViewState extends State<RecordView> {
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
      "https://goerli.infura.io/v3/9a5fa70ca9d74d7baf76f635173195b5";

  var _jsonString_onChain = "";

  Future<DeployedContract> getContract() async {
    //change this to your abi file.
    String abiFile = await rootBundle.loadString("assets/contract.json");
    //change this to your ContractAddress
    String contractAddress = "0xA1CA38d9F5e23aDf7df546e9c36ea5DF3a18a557";
    final contract = DeployedContract(ContractAbi.fromJson(abiFile, "Reef"),
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

  Future<void> readData(String account) async {
    final userAddress = EthereumAddress.fromHex(account);
    List<dynamic> results = await callFunction("read", [userAddress]);
    setState(() {
      _jsonString_onChain = results[0];
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

  Future<void> writeData(String account, String effortString) async {
    snackBar(label: "Move to metamask and verify.");
    final userAddress = EthereumAddress.fromHex(account);

    //obtain our contract from abi in json file
    final contract = await getContract();
    // extract function from json file
    final function = contract.function("write");
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
            parameters: [userAddress, _jsonString]),
        chainId: 5);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    snackBar(label: "verifying transaction");
    //set a 20 seconds delay to allow the transaction to be verified before trying to retrieve the balance
    Future.delayed(const Duration(seconds: 20), () {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      snackBar(label: "retrieving transaction");

      //getTokenBalance(account);

      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  //file
  bool _fileExists = false;
  late File _filePath;

  // First initialization of _json (if there is no json in the file)
  Map<String, dynamic> _json = {};
  late String _jsonString;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$kFileName');
  }

  void _writeJson(String key, dynamic value) async {
    // Initialize the local _filePath
    //final _filePath = await _localFile;

    //1. Create _newJson<Map> from input<TextField>
    Map<String, dynamic> _newJson = {key: value};
    print('1.(_writeJson) _newJson: $_newJson');

    //2. Update _json by adding _newJson<Map> -> _json<Map>
    _json.addAll(_newJson);
    print('2.(_writeJson) _json(updated): $_json');

    //3. Convert _json ->_jsonString
    _jsonString = jsonEncode(_json);
    print('3.(_writeJson) _jsonString: $_jsonString\n - \n');

    //4. Write _jsonString to the _filePath
    _filePath.writeAsString(_jsonString);
  }

  Future<String> _readJson() async {
    // Initialize _filePath
    _filePath = await _localFile;

    // 0. Check whether the _file exists
    _fileExists = await _filePath.exists();
    print('0. File exists? $_fileExists');

    // If the _file exists->read it: update initialized _json by what's in the _file
    if (_fileExists) {
      try {
        //1. Read _jsonString<String> from the _file.
        _jsonString = await _filePath.readAsString();
        print('1.(_readJson) _jsonString: $_jsonString');

        //2. Update initialized _json by converting _jsonString<String>->_json<Map>
        _json = jsonDecode(_jsonString);
        print('2.(_readJson) _json: $_json \n - \n');
        return _jsonString;
      } catch (e) {
        // Print exception errors
        print('Tried reading _file error: $e');
        return "error$e";
        // If encountering an error, return null
      }
    } else {
      return "filedoesntexist";
    }
  }

  @override
  void initState() {
    httpClient = Client();
    ethClient = Web3Client(blockchainUrl, httpClient);
    super.initState();
    // Instantiate _controllerKey and _controllerValue
    print('0. Initialized _json: $_json');
    _readJson();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var account = session?.accounts[0];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Record of your Efforts'),
        ),
        body: Padding(
          padding: EdgeInsets.only(top: 50, right: 40, bottom: 30, left: 40),
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text(
                'Blockchain',
                textAlign: TextAlign.left,
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    ?.copyWith(fontWeight: FontWeight.w700, color: Colors.blue),
              ),
              /*
              Text(
                  "Total working hours: ${_json.values.reduce((a, b) => a + b)} min"),
              */
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                  onPressed: session == null
                      ? () {
                          connectMetamaskWallet(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(minimumSize: Size(230, 50)),
                  child: Text("Connect wallet")),
              SizedBox(
                height: 5,
              ),
              ElevatedButton(
                onPressed: session == null
                    ? null
                    : () async {
                        writeData(account, _jsonString);
                      },
                style: ElevatedButton.styleFrom(minimumSize: Size(230, 50)),
                child: Text(
                  'Store data on blockchain',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                height: 60,
              ),
              Text(
                'Your Efforts',
                textAlign: TextAlign.left,
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    ?.copyWith(fontWeight: FontWeight.w700, color: Colors.blue),
              ),
              Flexible(
                fit: FlexFit.loose,
                //Expanded(
                child: FutureBuilder(
                  //FutureBuilder(
                  future: _readJson(),
                  initialData: const [],
                  builder:
                      (BuildContext context, AsyncSnapshot<Object> snapshot) {
                    var data = snapshot.data;
                    if (snapshot.hasData) {
                      return ListView.separated(
                        shrinkWrap: true,
                        //physics: const NeverScrollableScrollPhysics(),
                        itemCount: _json.length,
                        itemBuilder: (context, index) {
                          var key = _json.keys.elementAt(index);
                          return ListTile(
                            title: Text("$key"),
                            //leading: SizedBox(),
                            trailing: Text('${_json[key]} min '),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            const Divider(),
                      );
                    } else {
                      return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          // ignore: prefer_const_literals_to_create_immutables
                          children: [
                            const SizedBox(
                              height: 70,
                            ),
                            const Text('There is no data'),
                          ]);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
