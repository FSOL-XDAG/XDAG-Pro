import 'dart:isolate';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'package:xdag/common/color.dart';
import 'package:xdag/common/helper.dart';
import 'package:xdag/model/wallet_modal.dart';
import 'package:xdag/widget/button.dart';
import 'package:xdag/widget/input.dart';
import 'package:xdag/widget/nav_header.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:xdag/common/words.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;

class CreateWalletPageRouteParams {
  final bool isImport;
  CreateWalletPageRouteParams({required this.isImport});
}

class CreateWalletPage extends StatefulWidget {
  const CreateWalletPage({super.key});

  @override
  State<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<CreateWalletPage> {
  bool isPrivateKey = false;
  bool isAgree = false;
  late TextEditingController controller;
  String walletName = "";
  String importContent = "";
  bool isLoad = false;
  Isolate? isolate;
  List<String> mnemonicList = [];
  final _focusNode1 = FocusNode();
  final _focusNode2 = FocusNode();
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    ScreenHelper.initScreen(context);
  }

  @override
  void dispose() {
    controller.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    isolate?.kill(priority: Isolate.immediate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CreateWalletPageRouteParams args = CreateWalletPageRouteParams(isImport: false);
    if (ModalRoute.of(context)!.settings.arguments != null) {
      args = ModalRoute.of(context)!.settings.arguments as CreateWalletPageRouteParams;
    }
    int selectIndex = isPrivateKey ? 1 : 0;
    bool isButtonEnable = walletName.isNotEmpty && isAgree;
    if (args.isImport) {
      if (isPrivateKey) {
        isButtonEnable = isButtonEnable && importContent.length == 64;
      } else {
        List content = importContent.split(" ");
        isButtonEnable = isButtonEnable && content.length >= 12;
      }
    }
    void isolateFunction(SendPort sendPort) async {
      final receivePort = ReceivePort();
      sendPort.send(receivePort.sendPort);

      receivePort.listen((data) async {
        var isPrivateKey = data[0];
        var importContent = data[1] as String;
        importContent = importContent.isEmpty ? bip39.generateMnemonic(strength: 128) : importContent;
        bip32.BIP32 wallet = Helper.createWallet(isPrivate: isPrivateKey, content: importContent);
        String address = Helper.getAddressByWallet(wallet);
        sendPort.send(['success', address, importContent]);
      });
    }

    WalletModal walletModal = Provider.of<WalletModal>(context);
    return Scaffold(
      appBar: null,
      backgroundColor: DarkColors.bgColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (FocusScope.of(context).hasFocus) {
            FocusScope.of(context).unfocus();
          }
        },
        child: Column(
          children: [
            NavHeader(title: args.isImport ? AppLocalizations.of(context).importWallet : AppLocalizations.of(context).createWallet),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (args.isImport)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 50,
                            decoration: BoxDecoration(color: DarkColors.lineColor54, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: HeaderItem(
                                    title: AppLocalizations.of(context).mnemonic,
                                    index: 0,
                                    selectIndex: selectIndex,
                                    onPressed: () {
                                      controller.clear();
                                      setState(() {
                                        isPrivateKey = false;
                                        importContent = "";
                                        mnemonicList = [];
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: HeaderItem(
                                    title: AppLocalizations.of(context).privateKey,
                                    index: 1,
                                    selectIndex: selectIndex,
                                    onPressed: () {
                                      controller.clear();
                                      setState(() {
                                        isPrivateKey = true;
                                        importContent = "";
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          Text(isPrivateKey ? AppLocalizations.of(context).privateKey : AppLocalizations.of(context).mnemonic, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                          const SizedBox(height: 10),
                          AutoSizeTextField(
                            controller: controller,
                            focusNode: _focusNode1,
                            onChanged: (value) {
                              if (!isPrivateKey) {
                                List<String> list = value.split(" ");
                                if (list.isNotEmpty && value != "") {
                                  String lastWord = list[list.length - 1];
                                  list.removeLast();
                                  if (lastWord == " " || lastWord == "") {
                                    setState(() {
                                      mnemonicList = [];
                                    });
                                  } else {
                                    List<String> mnemonicList1 = [];
                                    for (String word in WORDLIST) {
                                      if (word.startsWith(lastWord) || word == lastWord) {
                                        bool isExist = false;
                                        for (String word1 in list) {
                                          if (word1 == word) {
                                            isExist = true;
                                            break;
                                          }
                                        }
                                        if (!isExist) mnemonicList1.add(word);
                                      }
                                    }
                                    setState(() {
                                      mnemonicList = mnemonicList1;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    mnemonicList = [];
                                  });
                                }
                              }
                              setState(() {
                                importContent = value;
                              });
                            },
                            keyboardAppearance: Brightness.dark,
                            minFontSize: 16,
                            maxLines: 10,
                            minLines: 3,
                            autofocus: args.isImport,
                            contextMenuBuilder: (context, editableTextState) {
                              final List<ContextMenuButtonItem> buttonItems = editableTextState.contextMenuButtonItems;
                              return AdaptiveTextSelectionToolbar.buttonItems(
                                anchors: editableTextState.contextMenuAnchors,
                                buttonItems: buttonItems,
                              );
                            },
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, fontFamily: 'RobotoMono'),
                            decoration: InputDecoration(
                              filled: true,
                              contentPadding: const EdgeInsets.all(15),
                              fillColor: DarkColors.blockColor,
                              hintText: isPrivateKey ? AppLocalizations.of(context).privateKey : AppLocalizations.of(context).mnemonic,
                              hintStyle: const TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'RobotoMono',
                                color: Colors.white54,
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: DarkColors.mainColor, width: 1),
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                        ],
                      )
                    else
                      Container(),
                    Text(AppLocalizations.of(context).walletName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    const SizedBox(height: 10),
                    Input(
                      isFocus: !args.isImport,
                      focusNode: _focusNode2,
                      hintText: AppLocalizations.of(context).walletName,
                      onChanged: (p0) {
                        setState(() {
                          walletName = p0;
                        });
                      },
                    ),
                    const SizedBox(height: 25),
                    MyRadioButton(
                      title: AppLocalizations.of(context).createWalletTips,
                      isCheck: isAgree,
                      onTap: () {
                        setState(() {
                          isAgree = !isAgree;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(color: DarkColors.lineColor, height: 1, width: double.infinity),
            KeyboardVisibilityBuilder(
              builder: (context, isKeyboardShow) {
                if (isKeyboardShow && args.isImport && !isPrivateKey) {
                  if (mnemonicList.isEmpty) {
                    return Container();
                  }
                  return SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: mnemonicList.length,
                      itemBuilder: (BuildContext buildContext, int index) {
                        String word = mnemonicList[index];
                        return TextButton(
                          onPressed: () {
                            String text = controller.text;
                            List<String> list = text.split(" ");
                            list.removeLast();
                            String newText = list.join(" ");
                            controller.text = newText == '' ? "$word " : "$newText $word ";
                            controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                            setState(() {
                              mnemonicList = [];
                              importContent = controller.text;
                            });
                          },
                          child: Text(word, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: DarkColors.mainColor)),
                        );
                      },
                    ),
                  );
                } else {
                  return Container(
                    margin: EdgeInsets.fromLTRB(15, 20, 15, ScreenHelper.bottomPadding > 0 ? ScreenHelper.bottomPadding : 20),
                    child: Column(
                      children: [
                        Button(
                          text: AppLocalizations.of(context).continueText,
                          width: ScreenHelper.screenWidth - 30,
                          bgColor: isButtonEnable ? DarkColors.mainColor : DarkColors.lineColor54,
                          textColor: Colors.white,
                          disable: !isButtonEnable,
                          isLoad: isLoad,
                          onPressed: () async {
                            if (isLoad) return;
                            setState(() {
                              isLoad = true;
                            });
                            // 新建一个线程处理
                            final receivePort = ReceivePort();
                            isolate = await Isolate.spawn(isolateFunction, receivePort.sendPort);
                            receivePort.listen((data) async {
                              if (data is SendPort) {
                                var subSendPort = data;
                                subSendPort.send([isPrivateKey, importContent]);
                              } else if (data is List<String>) {
                                try {
                                  await walletModal.createWallet(name: walletName, address: data[1], data: data[2], needBackUp: !args.isImport);
                                  setState(() {
                                    isLoad = false;
                                  });
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  setState(() {
                                    isLoad = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    backgroundColor: DarkColors.redColor,
                                    behavior: SnackBarBehavior.fixed,
                                    content: Text(
                                      data[1],
                                      style: const TextStyle(fontSize: 14, fontFamily: 'RobotoMono', fontWeight: FontWeight.w400, color: Colors.white),
                                    ),
                                  ));
                                }
                                isolate?.kill(priority: Isolate.immediate);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderItem extends StatelessWidget {
  final int selectIndex;
  final int index;
  final String title;
  // onpress
  final VoidCallback onPressed;
  const HeaderItem({super.key, required this.selectIndex, required this.index, required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(5),
      onPressed: onPressed,
      pressedOpacity: 1,
      child: Container(
        decoration: BoxDecoration(
          color: selectIndex != index ? Colors.transparent : DarkColors.bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ),
      ),
    );
  }
}