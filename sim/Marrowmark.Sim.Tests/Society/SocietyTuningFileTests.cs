using System;
using System.IO;
using System.Reflection;
using System.Text.Json;
using Marrowmark.Sim.Society;
using Xunit;

namespace Marrowmark.Sim.Tests.Society
{
    /// <summary>
    /// Guards shared/tuning/society.json against drifting from WarProfile.
    /// No prototype copy, deliberately: L88 mirrors only what the
    /// prototype exercises, and there is no war in Thornfield yet.
    /// </summary>
    public class SocietyTuningFileTests
    {
        private const string Canonical = "shared/tuning/society.json";

        private static string RepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null && !File.Exists(Path.Combine(dir.FullName, Canonical)))
                dir = dir.Parent;
            Assert.True(dir != null, $"Could not find {Canonical}");
            return dir!.FullName;
        }

        [Fact]
        public void War_tuning_matches_the_shared_file()
        {
            var root = JsonDocument
                .Parse(File.ReadAllText(Path.Combine(RepoRoot(), Canonical)))
                .RootElement;
            var profile = WarProfile.Default;

            foreach (var field in typeof(WarProfile).GetFields(
                         BindingFlags.Public | BindingFlags.Instance))
            {
                var key = char.ToLowerInvariant(field.Name[0]) + field.Name.Substring(1);
                JsonElement found = default;
                var hits = 0;
                foreach (var section in root.EnumerateObject())
                    if (section.Value.TryGetProperty(key, out var v)) { found = v; hits++; }

                Assert.True(hits == 1,
                    $"{key} appears {hits} times in {Canonical}; expected exactly 1");

                var expected = field.GetValue(profile);
                if (expected is float f) Assert.Equal(f, found.GetSingle(), 4);
                else if (expected is int i) Assert.Equal(i, found.GetInt32());
                else Assert.Fail($"Unhandled field type for {key}: {field.FieldType}");
            }
        }

        [Fact]
        public void The_shared_file_carries_no_numbers_nobody_owns()
        {
            var root = JsonDocument
                .Parse(File.ReadAllText(Path.Combine(RepoRoot(), Canonical)))
                .RootElement;
            var known = new System.Collections.Generic.HashSet<string>();
            foreach (var f in typeof(WarProfile).GetFields(BindingFlags.Public | BindingFlags.Instance))
                known.Add(char.ToLowerInvariant(f.Name[0]) + f.Name.Substring(1));

            foreach (var property in root.GetProperty("war").EnumerateObject())
                Assert.True(known.Contains(property.Name),
                    $"{Canonical} has \"war.{property.Name}\", which is not a field on WarProfile.");
        }
    }
}
