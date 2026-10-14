using System;
using System.IO;
using System.Reflection;
using System.Text.Json;
using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// Guards shared/tuning/weapons.json against drifting from the six
    /// family profiles and the technique profile. No prototype copy: the
    /// prototype has one sword and no techniques, and L88 mirrors only
    /// what it exercises.
    /// </summary>
    public class WeaponTuningFileTests
    {
        private const string Canonical = "shared/tuning/weapons.json";

        private static string RepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null && !File.Exists(Path.Combine(dir.FullName, Canonical)))
                dir = dir.Parent;
            Assert.True(dir != null, $"Could not find {Canonical}");
            return dir!.FullName;
        }

        private static JsonElement Load() =>
            JsonDocument.Parse(File.ReadAllText(Path.Combine(RepoRoot(), Canonical))).RootElement;

        private static string CamelCase(string name) =>
            char.ToLowerInvariant(name[0]) + name.Substring(1);

        private static void AssertMatches<T>(T profile, string section) where T : struct
        {
            Assert.True(Load().TryGetProperty(section, out var json), $"{Canonical} has no \"{section}\"");

            foreach (var field in typeof(T).GetFields(BindingFlags.Public | BindingFlags.Instance))
            {
                var key = CamelCase(field.Name);
                Assert.True(json.TryGetProperty(key, out var value),
                    $"{Canonical} is missing \"{section}.{key}\"");
                var actual = field.GetValue(profile)!;

                if (field.FieldType.IsEnum)
                    Assert.True(string.Equals(value.GetString(), actual.ToString(), StringComparison.OrdinalIgnoreCase),
                        $"{section}.{key} = \"{value.GetString()}\", profile has \"{actual}\"");
                else if (field.FieldType == typeof(bool))
                    Assert.True(value.GetBoolean() == (bool)actual, $"{section}.{key} differs");
                else if (field.FieldType == typeof(int))
                    Assert.True(value.GetInt32() == (int)actual, $"{section}.{key} differs");
                else
                    Assert.True(Math.Abs(value.GetSingle() - (float)actual) < 0.0001f,
                        $"{section}.{key} = {value.GetSingle()}, profile has {actual}");
            }

            foreach (var property in json.EnumerateObject())
                Assert.True(typeof(T).GetField(char.ToUpperInvariant(property.Name[0]) + property.Name.Substring(1)) != null,
                    $"{Canonical} has \"{section}.{property.Name}\", which is not a field on {typeof(T).Name}.");
        }

        [Fact]
        public void Every_family_matches_the_shared_file()
        {
            foreach (WeaponFamily f in Enum.GetValues(typeof(WeaponFamily)))
                AssertMatches(WeaponFamilyProfile.For(f), CamelCase(f.ToString()));
        }

        [Fact]
        public void Technique_tuning_matches_the_shared_file() =>
            AssertMatches(TechniqueProfile.Default, "technique");
    }
}
