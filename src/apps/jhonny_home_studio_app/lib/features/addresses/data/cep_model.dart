class CepModel {
  CepModel({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.localidade,
    required this.uf,
    required this.erro,
  });

  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade;
  final String uf;
  final bool erro;

  factory CepModel.fromJson(Map<String, dynamic> json) {
    return CepModel(
      cep: _readString(json, 'cep'),
      logradouro: _readString(json, 'logradouro'),
      complemento: _readString(json, 'complemento'),
      bairro: _readString(json, 'bairro'),
      localidade: _readString(json, 'localidade'),
      uf: _readString(json, 'uf'),
      erro: _readBool(json, 'erro'),
    );
  }
}

String _readString(Map<String, dynamic> json, String key) {
  return json[key]?.toString() ?? '';
}

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  return value?.toString().toLowerCase() == 'true';
}
