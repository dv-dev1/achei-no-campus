bool emailPermitido(String email) =>
    RegExp(r'^[^@\s]+@cs\.unipe\.edu\.br$')
        .hasMatch(email.trim().toLowerCase());

const categorias = [
  'Documentos',
  'Eletrônicos',
  'Chaves',
  'Carteira/Dinheiro',
  'Garrafa/Copo',
  'Roupa/Acessório',
  'Material escolar',
  'Outros',
];

const locais = [
  'Reitoria',
  'Bloco de Medicina',
  'Bloco de Odontologia',
  'Bloco de Enfermagem',
  'Bloco de Arquitetura',
  'EVA (Espaço de Vida Acadêmica)',
  'Biblioteca',
  'Centro de Informação',
  'Pós-Graduação',
  'Auditório',
  'Ginásio',
  'Piscina',
  'Clínica-escola',
  'Praça de alimentação/cantinas',
  'Passarela',
  'Estacionamento',
  'Outro',
];

const cloudinaryCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
const cloudinaryUploadPreset = String.fromEnvironment(
  'CLOUDINARY_UPLOAD_PRESET',
);
const limiteFotoBytes = 2 * 1024 * 1024;
