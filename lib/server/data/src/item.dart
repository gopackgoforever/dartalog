part of data;

class Item extends AIdData {
  String id = "";
  String get getId => id;
  set getId(String value) => id = value;

  String name = "";
  String get getName => name;
  set getName(String value) => name = value;

  String typeId;

  Map<String, String> values = new Map<String, String>();

  List<String> fileUploads = new List<String>();

  int copyCount = 0;

  List<ItemCopy> copies;
  ItemType type;

  Item();

}
