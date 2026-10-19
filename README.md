# Calc For All

Calculatrice Android Flutter avancée : scientifique + tracé de courbes + nombres complexes.

## Fonctionnalités

- Calculatrice scientifique classique (sin, cos, log, √, π…)
- Tracé de courbes en temps réel (fl_chart)
- Manipulation des nombres complexes (a+bi)
- Historique des calculs
- Thème clair / sombre
- Fonctionne 100 % hors ligne

## Compilation (GitHub Actions)

1. Va sur l’onglet **Actions** du dépôt
2. Clique sur **Build APK** → **Run workflow**
3. Attends la fin du job
4. Télécharge l’artefact `calc-for-all-apk`
5. Installe l’APK sur ton téléphone

## Structure

```
lib/
  main.dart
  core/
  data/
  features/
  widgets/
```

Développé pour être compilé uniquement depuis un téléphone + GitHub.
