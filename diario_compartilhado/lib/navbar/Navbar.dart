import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './persistent_bottom_bar_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  final _tab1navigatorKey = GlobalKey<NavigatorState>();
  final _tab2navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PersistentBottomBarScaffold(
      items: [
        PersistentTabItem(
          tab: TabPage1(),
          icon: Icons.bookmark_add,
          title: 'Meu Diário',
          navigatorkey: _tab1navigatorKey,
        ),
        PersistentTabItem(
          tab: TabPage2(),
          icon: Icons.book,
          title: 'Compartilhado',
          navigatorkey: _tab2navigatorKey,
        ),
      ],
    );
  }
}

class TabPage1 extends StatefulWidget {
  const TabPage1({Key? key}) : super(key: key);

  @override
  _TabPage1State createState() => _TabPage1State();
}

class _TabPage1State extends State<TabPage1> {
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final db = FirebaseFirestore.instance;

  String _selectedItem = '';
  DateTime _selectedDate =
      DateTime.now(); // Adicionado para armazenar a data selecionada
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    print('TabPage1 build');

    return Scaffold(
      appBar: AppBar(
          title: Text('Meu Diario',
              style: GoogleFonts.playfairDisplay(
                  textStyle:
                      TextStyle(color: Color.fromARGB(255, 99, 242, 201))))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
              style: GoogleFonts.playfairDisplay(
                  textStyle: TextStyle(
                      color: Color.fromARGB(255, 99, 242, 201),
                      letterSpacing: .5,
                      fontSize: 21)),
            ),
            Text(
              "Hora:  ${DateFormat('HH:mm').format(DateTime.now())}",
              style: GoogleFonts.playfairDisplay(
                  textStyle: TextStyle(
                      color: Color.fromARGB(255, 99, 242, 201),
                      letterSpacing: .5,
                      fontSize: 21)),
            ),
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );

                if (selectedDate != null && selectedDate != _selectedDate) {
                  setState(() {
                    _selectedDate = selectedDate;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            AutocompleteTextField(
              items: _countries,
              decoration: const InputDecoration(
                  labelText: 'Quem é?', border: OutlineInputBorder()),
              validator: (val) {
                if (_countries.contains(val)) {
                  return null;
                } else {
                  return 'Não foi';
                }
              },
              onItemSelect: (selected) {
                setState(() {
                  _selectedItem = selected;
                });
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                  labelText: 'Título', border: OutlineInputBorder()),
              validator: (val) {
                if (val != null && val.isNotEmpty) {
                  return null;
                } else {
                  return 'Digite um título';
                }
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: _entryController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Escreva algo...',
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 99, 242, 201),
                  onPrimary: Colors.black),
              // style: ElevatedeButton.styleFrom(primary: Color.fromARGB(255, 99, 242, 201)),
              onPressed: () async {
                final dia = <String, dynamic>{
                  "texto": _entryController.text,
                  "data": DateFormat('dd/MM/yyyy').format(_selectedDate),
                  "hora": DateFormat('HH:mm').format(DateTime.now()),
                  "nome": _selectedItem,
                  "titulo": _titleController.text,
                };
                db.collection("users").add(dia).then((DocumentReference doc) =>
                    print('DocumentSnapshot added with ID: ${doc.id}'));
                print("Ola");
              },
              child: Text(
                "Enviar",
                style: GoogleFonts.playfairDisplay(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TabPage2 extends StatelessWidget {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    print('TabPage2 build');
    return Scaffold(
      appBar: AppBar(title: Text('Compartilhado')),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection("users").snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Erro: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              var avatar = CircleAvatar(
                backgroundImage: NetworkImage(
                    "https://th.bing.com/th/id/R.432bc05ea96143b3a1e7e71a72922373?rik=afPQX2FmgFMwww&pid=ImgRaw&r=0"),
              );
              if (data["nome"] == "Sthefanny") {
                avatar = CircleAvatar(
                  backgroundImage: NetworkImage(
                      "https://i.pinimg.com/736x/c8/64/3c/c8643cd8e1a1d32b0837154f926448d7.jpg"),
                );
              }
              return ListTile(
                onTap: () => {
                  _showDialog(
                      context, data['texto'], data['data'], data["hora"])
                },
                leading: avatar,
                title: Text(data['titulo']),
                subtitle: Text(
                  "${data['data']}  ${data["hora"]}",
                ),
                trailing: Container(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () async {
                              await _editItem(context, document);
                            },
                            icon: Icon(
                              Icons.edit,
                              color: Colors.cyan,
                            )),
                        IconButton(
                            onPressed: () async {
                              await db
                                  .collection("users")
                                  .doc(document.id)
                                  .delete();
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ))
                      ],
                    )),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _editItem(
      BuildContext context, DocumentSnapshot document) async {
    TextEditingController textEditingController = TextEditingController();
    textEditingController.text = document['texto'];

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Item'),
          content: TextField(
            controller: textEditingController,
            decoration: InputDecoration(hintText: 'Novo texto'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Adicione aqui a lógica para salvar a edição
                db.collection("users").doc(document.id).update({
                  'texto': textEditingController.text,
                });
                Navigator.of(context).pop();
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

class Page1 extends StatelessWidget {
  final String inTab;

  const Page1(this.inTab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Page 1')),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('in $inTab Page 1'),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => Page2(inTab)));
                },
                child: Text('Go to page2'))
          ],
        ),
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  final String inTab;

  const Page2(this.inTab);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Page 2')),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }
}

class AutocompleteDropDown extends StatefulWidget {
  const AutocompleteDropDown({Key? key}) : super(key: key);

  @override
  State<AutocompleteDropDown> createState() => _SimpleDropDownState();
}

class _SimpleDropDownState extends State<AutocompleteDropDown> {
  String _selectedItem = '';
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Selected Country : $_selectedItem",
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 20),
                AutocompleteTextField(
                  items: _countries,
                  decoration: const InputDecoration(
                      labelText: 'Select country',
                      border: OutlineInputBorder()),
                  validator: (val) {
                    if (_countries.contains(val)) {
                      return null;
                    } else {
                      return 'Invalid Country';
                    }
                  },
                  onItemSelect: (selected) {
                    setState(() {
                      _selectedItem = selected;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () {
                      String message = 'Form invalid';
                      if (_formKey.currentState?.validate() ?? false) {
                        message = 'Form valid';
                      }
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(message)));
                    },
                    child: const Text("Continue"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showDialog(
    BuildContext context, String texto, String data, String hora) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Detalhes'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Texto:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(texto),
              SizedBox(height: 10),
              Text(
                'Data e Hora:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('$data  $hora'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Fechar'),
          ),
        ],
      );
    },
  );
}

class AutocompleteTextField extends StatefulWidget {
  final List<String> items;
  final Function(String) onItemSelect;
  final InputDecoration? decoration;
  final String? Function(String?)? validator;
  const AutocompleteTextField(
      {Key? key,
      required this.items,
      required this.onItemSelect,
      this.decoration,
      this.validator})
      : super(key: key);

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  final FocusNode _focusNode = FocusNode();
  late OverlayEntry _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late List<String> _filteredItems;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context)?.insert(_overlayEntry);
      } else {
        _overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onFieldChange,
        decoration: widget.decoration,
        validator: widget.validator,
      ),
    );
  }

  void _onFieldChange(String val) {
    setState(() {
      if (val == '') {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where(
                (element) => element.toLowerCase().contains(val.toLowerCase()))
            .toList();
      }
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
        builder: (context) => Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, size.height + 5.0),
                child: Material(
                  elevation: 4.0,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        final item = _filteredItems[index];
                        return ListTile(
                          title: Text(item),
                          onTap: () {
                            _controller.text = item;
                            _focusNode.unfocus();
                            widget.onItemSelect(item);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ));
  }
}

/// list of countries
final List<String> _countries = ["Sthefanny", "Luis"];
