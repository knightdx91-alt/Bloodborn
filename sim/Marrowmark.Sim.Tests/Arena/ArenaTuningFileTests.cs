using System;
using System.IO;
using System.Reflection;
using System.Text.Json;
using Marrowmark.Sim.Arena;
using Xunit;

namespace Marrowmark.Sim.Tests.Arena
{
    /// <summary>Guards shared/tuning/arena.json against ArenaProfile. No
    /// prototype copy: there is no arena in Thornfield.</summary>
    public class ArenaTuningFileTests
    {
        private const string Canonical = "shared/tuning/arena.json";

        private static string RepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null && !File.Exists(Path.Combine(dir.FullName, Canonical)))
                dir = dir.Parent;
            Assert.True(dir != null, $"Could not find {Canonical}");
            return dir!.FullName;
        }

        [Fact]
        public void Arena_tuning_matches_the_shared_file()
        {
            var root = JsonDocument
                .Parse(File.ReadAllText(Path.Combine(RepoRoot(), Canonical)))
                .RootElement;
            Assert.True(root.TryGetProperty("arena", out var section));
            var profile = ArenaProfile.Default;
            var known = new System.Collections.Generic.HashSet<string>();

            foreach (var field in typeof(ArenaProfile).GetFields(BindingFlags.Public | BindingFlags.Instance))
            {
                var key = char.ToLowerInvariant(field.Name[0]) + field.Name.Substring(1);
                known.Add(key);
                Assert.True(section.TryGetProperty(key, out var found), $"{Canonical} is missing \"arena.{key}\"");
                var expected = field.GetValue(profile);
                if (expected is float f) Assert.Equal(f, found.GetSingle(), 4);
                else if (expected is int i) Assert.Equal(i, found.GetInt32());
                else Assert.Fail($"Unhandled field type for {key}: {field.FieldType}");
            }

            foreach (var property in section.EnumerateObject())
                Assert.True(known.Contains(property.Name),
                    $"{Canonical} has \"arena.{property.Name}\", which is not a field on ArenaProfile.");
        }
    }
}
