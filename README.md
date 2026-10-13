# Perfomia Mobile

## Developpement local

Demarrer le backend Laravel sur `http://127.0.0.1:8000`, puis lancer Flutter
dans Chrome avec le navigateur pilote par Flutter :

```powershell
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 18080
```

Ne pas ouvrir manuellement l'URL de `flutter run -d web-server` dans un
navigateur sans l'extension Dart Debug Chrome : le point d'entree Dart peut
rester en attente et laisser le splash affiche. Pour un essai Web sans
debogueur, construire et servir la version compilee :

```powershell
flutter build web --no-tree-shake-icons --no-wasm-dry-run
npx http-server build/web -a 127.0.0.1 -p 5175 -c-1
```

Sur un emulateur Android, l'API locale est jointe par defaut via
`http://10.0.2.2:8000/api`. Sur un appareil physique, fournir l'adresse IP
joignable du PC avec `--dart-define=PERFOMIA_API_URL=http://IP_DU_PC:8000/api`.
