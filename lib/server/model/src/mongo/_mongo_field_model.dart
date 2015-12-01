part of model;

class _MongoFieldModel extends AFieldModel {
  static final Logger _log = new Logger('_MongoFieldModel');

  Future<Map<String,String>> getAllIDsAndNames() async {
    _log.info("Getting all field IDs and names ");
    _MongoDatabase con = await _MongoDatabase.getConnection();
    mongo.DbCollection collection = await con.getFieldsCollection();

    List results = await collection.find().toList();

    Map<String,String> output = new Map<String,String>();
    for (var result in results) {
      output[result["_id"]] = result["name"];
    }

    con.release();
    return output;
  }

  Future<Map<String,api.Field>> getAll() async {
    _log.info("Getting all fields");

    _MongoDatabase con = await _MongoDatabase.getConnection();
    mongo.DbCollection collection = await con.getFieldsCollection();

    List results = await collection.find().toList();

    Map<String,api.Field> output = new Map<String,api.Field>();
    for (var result in results) {
      mongo.ObjectId id = result["_id"];
      String str_id = id.toJson();
      output[str_id] = _createField(result);
    }
    con.release();
    return output;
  }

  static Future<api.Field> getByID(String id) {
    _log.info("Getting specific field by ID: ${id}");
  }

  Future write(api.Field field, [String id = null]) async {
    _MongoDatabase con = await _MongoDatabase.getConnection();
    mongo.DbCollection collection = await con.getFieldsCollection();


    if(tools.isNullOrWhitespace(id)) {
      Map data = _createMap(field);
      dynamic result = await collection.insert(data);
      return;
    } else {
      mongo.ObjectId obj_id = mongo.ObjectId.parse(id);

      var data = await collection.findOne({"_id": obj_id});
      if(data==null) {
        throw new Exception("Field not found ${field}");
      }

      _updateMap(field, data);
      await collection.save(data);
      con.release();
      return;
    }

  }

  api.Field _createField(Map data) {
    api.Field output = new api.Field();
    output.name = data["name"];
    output.type = data["type"];
    output.format = data["format"];
    return output;
  }

  Map _createMap(api.Field field) {
    Map data = new Map();
    _updateMap(field,data);
    return data;
  }

  void _updateMap(api.Field field, Map data) {
    data["name"] = field.name;
    data["type"] = field.type;
    data["format"] = field.format;
  }
}