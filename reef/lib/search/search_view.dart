import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

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

class SearchView extends StatefulWidget {
  const SearchView({super.key});
  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
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

  late String _jsonString_onChain = "";
  Map<String, dynamic> _json_onChain = {};

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

  Future<String> readData(String account) async {
    final userAddress = EthereumAddress.fromHex(account);
    List<dynamic> results = await callFunction("read", [userAddress]);
    print(results);
    setState(() {
      _jsonString_onChain = results[0];
      print(_jsonString_onChain);
      _json_onChain = jsonDecode(_jsonString_onChain);
      print(_json_onChain);
    });
    return _jsonString_onChain;
  }

  //send transaction using web3dart
  late Client httpClient;
  late Web3Client ethClient;
  //change this to your Infura goerli endpoints
  final String blockchainUrl =
      "https://goerli.infura.io/v3/9a5fa70ca9d74d7baf76f635173195b5";

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

    //jsonをvalueが大きい順に並び替える。
    _json = SplayTreeMap.of(_json, (a, b) {
      int compare = -_json[a]!.compareTo(_json[b]!);
      // compareが0（aとbの値が同じ場合）なら1（aがbよりも大きい場合）に置き換える。
      return compare == 0 ? 1 : compare;
    });
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

  String _text = '';
  String walletID = "";
  void _handleText(String e) {
    setState(() {
      _text = e;
    });
  }

  @override
  Widget build(BuildContext context) {
    var account = session?.accounts[0];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Look for data'),
        ),
        body: Padding(
          padding: EdgeInsets.only(top: 50, right: 40, bottom: 30, left: 40),
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text(
                'Look for data',
                textAlign: TextAlign.left,
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    ?.copyWith(fontWeight: FontWeight.w700, color: Colors.blue),
              ),
              TextField(
                enabled: true,
                style: TextStyle(color: Colors.black),
                obscureText: false,
                maxLines: 1,
                //パスワード
                onChanged: _handleText,
                decoration: const InputDecoration(
                  hintText: 'Enter the walletID',
                ),
              ),
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () async {
                  walletID = _text;
                  readData(walletID);
                },
                style: ElevatedButton.styleFrom(minimumSize: Size(230, 50)),
                child: Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                height: 60,
              ),
              Text(
                'Someone\' Efforts',
                textAlign: TextAlign.left,
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    ?.copyWith(fontWeight: FontWeight.w700, color: Colors.blue),
              ),
              /*_jsonString_onChain == ""
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      // ignore: prefer_const_literals_to_create_immutables
                      children: [
                        const SizedBox(
                          height: 70,
                        ),
                        const Text('There is no stored data'),
                      ],
                    )
                  : */
              Flexible(
                fit: FlexFit.loose,
                //Expanded(
                child: FutureBuilder(
                  //FutureBuilder(
                  future: readData(walletID), ////
                  initialData: const [""],
                  builder:
                      (BuildContext context, AsyncSnapshot<Object> snapshot) {
                    //var data = snapshot.data;
                    if (snapshot.hasData) {
                      return ListView.separated(
                        shrinkWrap: true,
                        //physics: const NeverScrollableScrollPhysics(),
                        itemCount: _json_onChain.length,
                        itemBuilder: (context, index) {
                          var key = _json_onChain.keys.elementAt(index);
                          return ListTile(
                            title: Text("$key"),
                            //leading: SizedBox(),
                            trailing: Text('${_json_onChain[key]} min '),
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
                            height: 40,
                          ),
                          const Text('There is no data'),
                        ],
                      );
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
